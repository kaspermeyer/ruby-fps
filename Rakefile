require 'rubygems'
require 'bundler/setup'
require 'releasy'

Releasy::Project.new do
  name "Ruby FPS"
  version "0.1.0"
  verbose

  executable "init.rb"
  files ["*.rb", "assets/*.png"]
  add_link "https://github.com/kafkatamura/ruby-fps", "Ruby FPS on Github"
  exclude_encoding

  add_build :osx_app do
    url "com.github.rubyfps"
    wrapper "wrapper/gosu-mac-wrapper-0.7.44.tar.gz"
    add_package :tar_gz
  end

  add_build :windows_folder do
    executable_type :windows
    add_package :exe
  end

  add_build :windows_wrapped do
    wrapper "wrapper/ruby-1.9.3-p448-i386-mingw32.7z"
    executable_type :windows
    exclude_tcl_tk
    add_package :zip
  end

  add_deploy :local
end

