module Fastlane
  module Actions
    class OneskyDownloadListingAction < Action
      def self.run(params)
        Actions.verify_gem!('onesky-ruby')
        require 'onesky'
        require 'json'

        client = ::Onesky::Client.new(params[:public_key], params[:secret_key])
        project = client.project(params[:project_id])

        JSON.parse(project.list_language)['data'].each do |x|
          if (x['is_ready_to_publish'])
            locale = Helper::OneskyHelper.normalize(x['code'])

            dest_dir = "#{params[:destination]}/#{locale}/"

            UI.message "Downloading translation #{locale} from OneSky to: #{dest_dir}"
            resp = JSON.parse(project.export_app_description(locale: locale))['data']

            FileUtils.mkdir_p(dest_dir) unless File.exists?(dest_dir)
            File.write "#{dest_dir}/name.txt", "#{resp['APP_NAME']}\n"
            File.write "#{dest_dir}/subtitle.txt", "#{resp['APP_SUBTITLE']}\n"
            File.write "#{dest_dir}/description.txt", "#{resp['APP_DESCRIPTION']}\n"
            File.write "#{dest_dir}/release_notes.txt", "#{resp['APP_VERSION_DESCRIPTION']}\n"
            File.write "#{dest_dir}/keywords.txt", "#{resp['APP_KEYWORD'].map { |key, value| value }.join(", ")}\n"
          end
        end
      end

      def self.description
        'Download a iTC translation text from OneSky'
      end

      def self.authors
        ['sugoi-wada']
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :public_key,
                                       env_name: 'ONESKY_PUBLIC_KEY',
                                       description: 'Public key for OneSky',
                                       is_string: true,
                                       optional: false,
                                       verify_block: proc do |value|
                                         raise "No Public Key for OneSky given, pass using `public_key: 'token'`".red unless value and !value.empty?
                                       end),
          FastlaneCore::ConfigItem.new(key: :secret_key,
                                       env_name: 'ONESKY_SECRET_KEY',
                                       description: 'Secret Key for OneSky',
                                       is_string: true,
                                       optional: false,
                                       verify_block: proc do |value|
                                         raise "No Secret Key for OneSky given, pass using `secret_key: 'token'`".red unless value and !value.empty?
                                       end),
          FastlaneCore::ConfigItem.new(key: :project_id,
                                       env_name: 'ONESKY_PROJECT_ID',
                                       description: 'Project Id to upload file to',
                                       optional: false,
                                       verify_block: proc do |value|
                                         raise "No project id given, pass using `project_id: 'id'`".red unless value and !value.empty?
                                       end),
          FastlaneCore::ConfigItem.new(key: :destination,
                                       env_name: 'ONESKY_DOWNLOAD_DESTINATION',
                                       description: 'Destination directory to write the downloaded file to',
                                       is_string: true,
                                       optional: true,
                                       default_value: 'fastlane/metadata')
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
