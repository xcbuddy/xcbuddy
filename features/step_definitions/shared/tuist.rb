# frozen_string_literal: true

Given(/tuist is available/) do
  system("swift", "build")
end

Then(/tuist generates the project/) do
  system("swift", "run", "tuist", "generate", "--path", @dir)
  @workspace_path = Dir.glob(File.join(@dir, "*.xcworkspace")).first
end

Then(/tuist sets up the project/) do
  system("swift", "run", "tuist", "up", "--path", @dir)
  @workspace_path = Dir.glob(File.join(@dir, "*.xcworkspace")).first
end

Then(/tuist generates reports error "(.+)"/) do |error|
  stdin, stdout, stderr, wait_thr = Open3.popen3("swift", "run", "tuist", "generate", "--path", @dir) 
  if stderr.gets.start_with?(error) == false then
    fail "Error has not been reported"
  end
  if wait_thr.value.exitstatus != 1 then
    fail "Exit status is not 1"
  end
end
