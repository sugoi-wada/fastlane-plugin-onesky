module Fastlane
  module Actions
    class OneskyDownloadAction < Action
      def self.run(params)
        Actions.verify_gem!('onesky-ruby')
        require 'onesky'
        require 'json'

        client = ::Onesky::Client.new(params[:public_key], params[:secret_key])
        project = client.project(params[:project_id])

        files = JSON.parse(project.list_file)['data'].map { |x| x['file_name'] }

        JSON.parse(project.list_language)['data'].each do |x|
          if (x['is_ready_to_publish'])
            locale = x['custom_locale'] || x['code']
            files.each do |file_name|
              dest_dir = "#{params[:destination]}/#{locale}.lproj"

              UI.success "Downloading translation #{x['english_name']} (#{x['code']}) of file #{file_name} from OneSky to: #{dest_dir}"
              resp = project.export_translation(source_file_name: file_name, locale: x['code'])

              FileUtils.mkdir_p(dest_dir) unless File.exists?(dest_dir)
              File.open("#{dest_dir}/#{file_name}", 'w') { |file| file.write(resp) }
            end
          end
        end
      end

      def self.description
        'Download a translation file from OneSky'
      end

      def self.authors
        ['danielkiedrowski']
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
                                       optional: false,
                                       verify_block: proc do |value|
                                         raise "Please specify the filename of the desrtination file you want to download the translations to using `destination: 'filename'`".red unless value and !value.empty?
                                       end)
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
