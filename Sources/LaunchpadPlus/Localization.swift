import Foundation
import SwiftUI

extension String {
    @MainActor
    var localized: String {
        return NSLocalizedString(self, bundle: L10n.currentBundle, comment: "")
    }
}

@MainActor
struct L10n {
    fileprivate(set) static var currentBundle: Bundle = .module
    
    static func updateLanguage(_ language: AppListViewModel.AppLanguage) {
        if language == .system {
            currentBundle = .module
        } else {
            if let path = Bundle.module.path(forResource: language.rawValue, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                currentBundle = bundle
            } else {
                currentBundle = .module
            }
        }
    }
    
    static var systemLanguage: String { "system_language".localized }
    static var searchPlaceholder: String { "search_placeholder".localized }
    static var gridSettings: String { "grid_settings".localized }
    static var rows: String { "rows".localized }
    static var cols: String { "cols".localized }
    static var showUtilities: String { "show_utilities".localized }
    static var hideUtilities: String { "hide_utilities".localized }
    static var sortBy: String { "sort_by".localized }
    static var alphabetical: String { "Alphabetical".localized }
    static var installDate: String { "Install Date".localized }
    static var mostUsed: String { "Most Used".localized }
    static var manual: String { "Manual".localized }
    static var hotkeySettings: String { "hotkey_settings".localized }
    static var changeShortcut: String { "change_shortcut".localized }
    static func currentHotkey(_ hotkey: String) -> String {
        String(format: "current_hotkey".localized, hotkey)
    }
    static var advanced: String { "advanced".localized }
    static var launchAtLogin: String { "launch_at_login".localized }
    static var showRecentApps: String { "show_recent_apps".localized }
    static var recentPosition: String { "recent_position".localized }
    static var side: String { "Side".localized }
    static var bottom: String { "Bottom".localized }
    static var unhideAllApps: String { "unhide_all_apps".localized }
    static var helpDocumentation: String { "help_documentation".localized }
    static var aboutLaunchpadPlus: String { "about_launchpadplus".localized }
    static var quitLaunchpadPlus: String { "quit_launchpadplus".localized }
    static var recentHeader: String { "recent_header".localized }
    static var folderNamePlaceholder: String { "folder_name_placeholder".localized }
    static var dissolveFolder: String { "dissolve_folder".localized }
    static var addToFavorites: String { "add_to_favorites".localized }
    static var removeFromFavorites: String { "remove_from_favorites".localized }
    static var hideApp: String { "hide_app".localized }
    static var moveToTrash: String { "move_to_trash".localized }
    static var helpTitle: String { "help_title".localized }
    static var navigation: String { "navigation".localized }
    static var folders: String { "folders".localized }
    static var recentAppsHeader: String { "recent_apps".localized }
    static var proTips: String { "pro_tips".localized }
    static func versionInfo(_ version: String) -> String {
        String(format: "version_info".localized, version)
    }
    static var appDescription: String { "app_description".localized }
    static var craftedWith: String { "crafted_with".localized }
    static var close: String { "close".localized }
    static var recording: String { "recording".localized }
    static var noAppsFound: String { "no_apps_found".localized }
    static var recordNewShortcut: String { "record_new_shortcut".localized }
    static var recordShortcutDesc: String { "record_shortcut_desc".localized }
    static var waitingForKeys: String { "waiting_for_keys".localized }
    static var cancel: String { "cancel".localized }
    static var saveShortcut: String { "save_shortcut".localized }
    static var manageHiddenApps: String { "manage_hidden_apps".localized }
    static var moveOutOfFolder: String { "move_out_of_folder".localized }
    static var hiddenAppsTitle: String { "hidden_apps_title".localized }
    static var noHiddenApps: String { "no_hidden_apps".localized }
    static var unhide: String { "unhide".localized }
    static var unhideAll: String { "unhide_all".localized }
    static var language: String { "language".localized }
    
    // Help Items
    static var navItem1: String { "nav_item_1".localized }
    static var navItem2: String { "nav_item_2".localized }
    static var navItem3: String { "nav_item_3".localized }
    static var navItem4: String { "nav_item_4".localized }
    static var folderItem1: String { "folder_item_1".localized }
    static var folderItem2: String { "folder_item_2".localized }
    static var folderItem3: String { "folder_item_3".localized }
    static var recentAppsItem1: String { "recent_apps_item_1".localized }
    static var recentAppsItem2: String { "recent_apps_item_2".localized }
    static var searchItem1: String { "search_item_1".localized }
    static var searchItem2: String { "search_item_2".localized }
    static var managementItem1: String { "management_item_1".localized }
    static var managementItem2: String { "management_item_2".localized }
    static var managementItem3: String { "management_item_3".localized }
    static var managementItem4: String { "management_item_4".localized }
    static var proTipsItem1: String { "pro_tips_item_1".localized }
    static var proTipsItem2: String { "pro_tips_item_2".localized }
}
