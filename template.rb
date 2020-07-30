##
# Documentation for Rails templates:
#   https://guides.rubyonrails.org/rails_application_templates.html
#
# Rails templates make extensive use of Thor. If you can't find docs for a
# function in the guide above, search the Thor docs.
#
def main # rubocop:disable Metrics/MethodLength
  add_template_repository_to_source_path

  append_to_file "config/puma.rb" do
    <<~EO_PUMA_CONFIG
      if ENV.fetch("RAILS_ENV") == "development" && ENV.fetch("LOCAL_SSL_ENABLE", "").downcase == "yes"
        local_ssl_port = ENV.fetch("LOCAL_SSL_PORT", "3001")
        local_ssl_options = {
          key: ENV.fetch("LOCAL_SSL_PRIVATE_KEY_FILE"),
          cert: ENV.fetch("LOCAL_SSL_CERT_FILE"),
          verify_mode: "none"
        }

        ssl_bind "127.0.0.1", local_ssl_port, local_ssl_options
      end
    EO_PUMA_CONFIG
  end

  append_to_file "example.env" do
    <<~EO_SSL_CONFIG

      LOCAL_SSL_ENABLE="yes"
      LOCAL_SSL_PORT="3001"
      LOCAL_SSL_PRIVATE_KEY_FILE=".ssl/dev-private-key.pem"
      LOCAL_SSL_CERT_FILE=".ssl/dev-cert.pem"
    EO_SSL_CONFIG
  end

  append_to_file "README.md" do
    <<~EO_README

      ### Running SSL in local development

      ```sh
      # You must have `mkcert` installed
      # $ brew install mkcert # macOS
      # See https://github.com/FiloSottile/mkcert for Window and Linux installation options

      # Install the mkcert Root CA (you only have to do this once after you first install `mkcert`)
      $ mkcert -install

      # Create ./.ssl/ dir in your app folder
      mkdir .ssl

      # Generate cert & corresponding private key
      mkcert --cert-file .ssl/dev-cert.pem --key-file .ssl/dev-private-key.pem localhost 127.0.0.1

      # Then just start the rails server as normal.
      ```
    EO_README
  end
end

# Add this template directory to source_paths so that Thor actions like
# copy_file and template resolve against our source files. If this file was
# invoked remotely via HTTP, that means the files are not present locally.
# In that case, use `git clone` to download them to a local temporary dir.
def add_template_repository_to_source_path # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  if __FILE__.match?(%r{\Ahttps?://})
    require "tmpdir"
    source_paths.unshift(tempdir = Dir.mktmpdir("rails-template-pdf-rendering"))
    at_exit { FileUtils.remove_entry(tempdir) }
    git clone: [
      "--quiet",
      "https://github.com/ackama/rails-template-pdf-rendering.git",
      tempdir
    ].map(&:shellescape).join(" ")

    if (branch = __FILE__[%r{rails-template/(.+)/template.rb}, 1])
      Dir.chdir(tempdir) { git checkout: branch }
    end
  else
    source_paths.unshift(File.dirname(__FILE__))
  end
end

main
