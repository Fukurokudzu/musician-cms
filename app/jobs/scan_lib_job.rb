class ScanLibJob < ApplicationJob
  queue_as :default

  def perform(artist)
    Dir.chdir(Rails.root.join('app', 'music', artist)) do
      Dir.glob('*').map do |folder|
        p folder if File.directory?(folder)
      end
    end

  end
end
