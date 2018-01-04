module Fastlane
  module Actions
    class OneskyUploadAction < Action
      def self.run(params)
        Actions.verify_gem!('onesky-ruby')
        require 'onesky'
        require 'json'

        client = ::Onesky::Client.new(params[:public_key], params[:secret_key])
        project = client.project(params[:project_id])

        UI.success 'Starting the upload to OneSky'

        files = JSON.parse(project.list_file)['data'].map { |x| x['file_name'] }

        Dir::chdir(params[:source_dir])
        Dir::glob('*.lproj').each do |lproj_dir|
          files.each do |file_name|
            file_path = "#{Dir::pwd}/#{lproj_dir}/#{file_name}"

            unless File::exist?(file_path) then
              UI.message "missing file at #{file_path}. Skip."
              next
            end

            locale = lproj_dir.gsub(".lproj", "")

            UI.message "Uploading translation #{locale} of file #{file_path} to OneSky..."

            resp = project.upload_file(file: file_path, file_format: params[:strings_file_format], locale: locale, is_keeping_all_strings: !params[:deprecate_missing])

            if resp.code == 201
              UI.success "#{file_path} was successfully uploaded to project #{params[:project_id]} in OneSky"
            else
              UI.error "Error uploading file to OneSky, Status code is #{resp.code}"
            end
          end
        end
      end

      def self.description
        'Upload a strings file to OneSky'
      end

      def self.authors
        ['JMoravec', 'joshrlesch', 'danielkiedrowski']
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
          FastlaneCore::ConfigItem.new(key: :source_dir,
                                       env_name: 'ONESKY_UPLOAD_SOURCE',
                                       description: 'Directory for the strings file to upload',
                                       is_string: true,
                                       optional: false,
                                       verify_block: proc do |value|
                                         raise "Couldn't find file at path '#{value}'".red unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :strings_file_format,
                                       env_name: 'ONESKY_STRINGS_FORMAT',
                                       description: 'Format of the strings file: see https://github.com/onesky/api-documentation-platform/blob/master/reference/format.md',
                                       is_string: true,
                                       optional: false,
                                       verify_block: proc do |value|
                                         raise 'No file format given'.red unless value and !value.empty?
                                       end),
          FastlaneCore::ConfigItem.new(key: :deprecate_missing,
                                       env_name: 'ONESKY_DEPRECATE_MISSING',
                                       description: 'Should missing phrases be marked as deprecated in OneSky?',
                                       is_string: false,
                                       optional: true,
                                       default_value: false)
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
