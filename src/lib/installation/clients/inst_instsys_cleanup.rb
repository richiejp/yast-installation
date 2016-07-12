# ------------------------------------------------------------------------------
# Copyright (c) 2016 SUSE LLC, All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as published by the
# Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
# ------------------------------------------------------------------------------

#

require "fileutils"

require "yast"
require "yast2/hw_detection"

module Yast
  class InstInstsysCleanup < Client
    # memory limit for removing the kernel modules from inst-sys (1GB)
    MODULES_WATERMARK = 1 << 30

    # memory limit for removing the libzypp metadata cache (640MB)
    LIBZYPP_WATERMARK = 640 * (1 << 20)
    LIBZYPP_CACHE_PATH = "/var/cache/zypp/raw".freeze

    def main
      textdomain "installation"

      Yast.import "Mode"
      Yast.import "Stage"

      if !Stage.initial && (Mode.install || Mode.update)
        log.warning("Skipping cleanup (not in the initial installation)")
        return :auto
      end

      # memory size in MB
      memory_mb = Yast2::HwDetection.memory << 20

      # run the cleaning actions depending on the available memory

      umount_kernel_modules if memory_mb < MODULES_WATERMARK

      cleanup_zypp_cache if memory_mb < LIBZYPP_WATERMARK

      :auto
    end

  private

    # Remove the libzypp downloaded repository metadata.
    # Libzypp has "raw" and "solv" caches, the "solv" is built from "raw"
    # but it cannot be removed because libzypp keeps the file open.
    # The "raw" files will be later downloaded again automatically when needed.
    def cleanup_zypp_cache
      log.info("inst-sys cleanup: removing libzypp cache (#{LIBZYPP_CACHE_PATH})")
      log_space_usage("Before removing libzypp cache:")

      # make sure we do not collide with Yast::FileUtils...
      ::FileUtils.rm_rf(LIBZYPP_CACHE_PATH)

      log_space_usage("After removing libzypp cache:")
    end

    def umount_kernel_modules
      # TODO: verify that the modules are present
      log.info("inst-sys cleanup: removing the kernel modules inst-sys image")
      log_space_usage("Before removing kernel modules:")

      # TODO: get the respective loop device name
      # TODO: unmount the loop device
      # TODO: remove the loop device setup (losetup -d)
      # TODO: remove the image file

      log_space_usage("After removing kernel modules:")
    end

    def log_space_usage(msg)
      log.info(msg)
      log.info("disk usage in MB ('df -m'):")
      log.info(`df -m`)
      log.info("memory usage in MB ('free -m'):")
      log.info(`free -m`)
    end
  end
end
