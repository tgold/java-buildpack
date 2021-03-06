# Encoding: utf-8
# Cloud Foundry Java Buildpack
# Copyright 2013 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'java_buildpack/framework'
require 'java_buildpack/repository/configured_item'
require 'java_buildpack/util/application_cache'
require 'java_buildpack/util/play_utils'

module JavaBuildpack::Framework

  # Encapsulates the detect, compile, and release functionality for enabling cloud auto-reconfiguration in Play
  # applications that use JPA. Note that Spring auto-reconfiguration is covered by the SpringAutoReconfiguration
  # framework. The reconfiguration performed here is to override Play application configuration to bind a Play
  # application to cloud resources.
  class PlayJpaPlugin

    # Creates an instance, passing in an arbitrary collection of options.
    #
    # @param [Hash] context the context that is provided to the instance
    # @option context [String] :app_dir the directory that the application exists in
    # @option context [String] :lib_directory the directory that additional libraries are placed in
    # @option context [Hash] :configuration the properties provided by the user
    def initialize(context = {})
      context.each { |key, value| instance_variable_set("@#{key}", value) }
      @version, @uri = PlayJpaPlugin.find_play_jpa_plugin(@app_dir, @configuration)
    end

    # Detects whether this application is suitable for auto-reconfiguration
    #
    # @return [String] returns +play-jpa-plugin-<version>+ if the application is a candidate for JPA
    #                  auto-reconfiguration otherwise returns +nil+
    def detect
      @version ? id(@version) : nil
    end

    # Downloads the Auto-reconfiguration JAR
    #
    # @return [void]
    def compile
      JavaBuildpack::Util::ApplicationCache.download_jar(@version, @uri, 'Play JPA Plugin', jar_name(@version), @lib_directory)
    end

    # Does nothing
    #
    # @return [void]
    def release
    end

    private

    PLAY_JPA_PLUGIN_JAR = '*play-java-jpa*.jar'.freeze

    def self.candidate?(app_dir)
      candidate = false

      root = JavaBuildpack::Util::PlayUtils.root app_dir
      candidate = uses_jpa?(root) || play20?(root) if root

      candidate
    end

    def self.find_play_jpa_plugin(app_dir, configuration)
      candidate?(app_dir) ? JavaBuildpack::Repository::ConfiguredItem.find_item(configuration) : [nil, nil]
    end

    def id(version)
      "play-jpa-plugin-#{version}"
    end

    def jar_name(version)
      "#{id version}.jar"
    end

    def self.play20?(root)
      JavaBuildpack::Util::PlayUtils.version(root) =~ /2.0.[\d]+/
    end

    def self.uses_jpa?(root)
      lib = File.join JavaBuildpack::Util::PlayUtils.lib(root), PLAY_JPA_PLUGIN_JAR
      staged = File.join JavaBuildpack::Util::PlayUtils.staged(root), PLAY_JPA_PLUGIN_JAR
      Dir[lib, staged].first
    end

  end

end
