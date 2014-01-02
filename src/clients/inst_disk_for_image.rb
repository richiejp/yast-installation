# encoding: utf-8

# ------------------------------------------------------------------------------
# Copyright (c) 2013 Novell, Inc. All Rights Reserved.
#
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as published by the
# Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail, you may find
# current contact information at www.novell.com.
# ------------------------------------------------------------------------------
#
# Summary: Ask for disk to deploy image to
#

module Yast
  class InstDiskForImageClient < Client
    def main
      Yast.import "UI"

      textdomain "installation"

      Yast.import "Popup"
      Yast.import "GetInstArgs"
      Yast.import "Wizard"
      Yast.import "Storage"
      Yast.import "InstData"

      @test_mode = WFM.Args.include?("test")

      Wizard.CreateDialog #if @test_mode

      show_disk_for_image_dialog

      ret = nil
      disk = nil

      continue_buttons = [:next, :back, :close, :abort]
      while !continue_buttons.include?(ret) do
        ret = UI.UserInput

        if ret == :next
          disk = UI.QueryWidget(Id(:disk), :Value)
          ret = WFM.CallFunction("inst_doit", [])
          ret = nil unless ret == :next

          InstData.image_target_disk = disk
        elsif ret == :abort
          ret = nil unless Popup.ConfirmAbort(:painless)
        end
      end


      Wizard.CloseDialog if @test_mode

      return ret
    end


    private

    def disks_to_use
      target_map = Storage.GetTargetMap
      Builtins.y2milestone("TM: %1", target_map)
      supported_types = [ :CT_DISK, :CT_DMRAID, :CT_DMMULTIPATH, :CT_MDPART ]
      used_by_blacklist = [ :CT_DMRAID, :CT_DMMULTIPATH, :CT_MDPART ]
      target_map.select { | key, value |
        (supported_types.include? value["type"]) && (! used_by_blacklist.include? value["used_by"])
      }.keys
    end

    def disk_for_image_dialog
      MarginBox(1, 0.5,
        VBox(
          Left(Label(_("Select the disk to deploy the image to."))),
          Left(Label(_("All data on the disk will be destroyed!!!"))),
          VSpacing(0.5),
          SelectionBox(Id(:disk), _("&Disk to Use"), disks_to_use)
        )
      )
    end

    def disk_for_image_help_text
      _("Select the disk, which the image will be deployed to.
All data on the disk will be destroyed and the disk will be
partitioned as defined in the image.")
    end

    def show_disk_for_image_dialog
      Wizard.SetContents(
        _("Hard Disk to Deploy To"),
        disk_for_image_dialog,
        disk_for_image_help_text,
        GetInstArgs.enable_back || @test_mode,
        GetInstArgs.enable_next || @test_mode
      )
    end
  end
end

Yast::InstDiskForImageClient.new.main
