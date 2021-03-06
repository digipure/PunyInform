#!/bin/ruby

$is_windows = (ENV['OS'] == 'Windows_NT')

def checkforfailures() 
    if $some_tests_failed then
        puts "\nSOME TESTS FAILED!"
        exit
    end
end

def runtest(filename, version, inform_args)
    basename = File.basename(filename, ".inf")
    command_file = basename + ".cmd"
    transcript_file = basename + ".scr"
    output_file = basename + ".output"
    template_file = basename + ".txt"

    if $is_windows then
        puts "Someone needs to provide Windows commands"
        exit
    else
        inform_cmd = "inform +.  +../lib -v#{version} #{inform_args} #{filename}"
        frotz_cmd = "frotz #{basename}.z#{version} < #{command_file}"
        prune_cmd = "tail +6 #{transcript_file} | grep -v PunyInform > #{output_file}"
        diff_cmd = "diff -Z #{template_file} #{output_file}"
        diff_cmd_ignore_banner = "diff -Z #{template_file} #{output_file} | grep -v PunyInform | tail +3"
    end
    # Remove old transcripts
    File.delete transcript_file if File.exist? transcript_file

    print "#{basename}: "
    begin
        result = %x[#{inform_cmd}]
        if result.include? "(no output)" then
            puts result
            raise Errno::ENOENT
        end
        result = %x[#{frotz_cmd}]
        result = %x[#{prune_cmd}]
        result = %x[#{diff_cmd_ignore_banner}]
        if result.empty? then
            puts "passed"
        else
            puts "failed"
            $some_tests_failed = true
            puts %x[#{diff_cmd}]
        end
    rescue Errno::ENOENT
        puts "unable to run this test (compilation error?)"
        exit
    end
end

$some_tests_failed = false

puts "Testing v3 debug"
Dir["*.inf"].sort.each { |filename| runtest filename, 3, "-D" }
checkforfailures

puts "Testing v3 release"
Dir["*.inf"].sort.each { |filename| runtest filename, 3, "" }
checkforfailures

puts "Testing v5 debug"
Dir["*.inf"].sort.each { |filename| runtest filename, 5, "-D" }
checkforfailures

puts "Testing v5 release"
Dir["*.inf"].sort.each { |filename| runtest filename, 5, "" }
checkforfailures

puts "\nALL TESTS PASSED"
