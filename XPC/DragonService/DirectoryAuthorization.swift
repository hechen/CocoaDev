//
//  DirectoryAuthorization.swift
//  Venom
//
//  Created by chen he on 2019/7/4.
//  Copyright © 2019 chen he. All rights reserved.
//

import Foundation

final class DirectoryAuthorization {
    static let shared = DirectoryAuthorization()
    private init() {}
    
    func authorize(_ path: String, completion: ((Bool)->Void)? = nil) {
        
        VenomLog.info("Try to auth \(path)")
        
        let key = "bookmark:\(path)"
        
        if !path.isEmpty {
            
            if let bookmarkData = AppEnvironment.current.userDefaults.data(for: key) {
                
                if resolveBookmark(bookmarkData, key: key) {
                    VenomLog.info("Authorization Done")
                    
                    completion?(true)
                } else {
                    VenomLog.error("Authorization Error")
                    
                    completion?(false)
                }
                
                return
            }
        }
        
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        
        if !path.isEmpty {
            panel.directoryURL = URL(fileURLWithPath: path, isDirectory: true)
        }
        
        panel.message = "Venom is a sandboxing app which needs be authorized to access your directory for the first time."
        panel.prompt = "Authorize"
        panel.begin(completionHandler: { [weak self] in
            guard let self = self else { return }
            switch $0 {
            case .OK:
                let url = panel.urls.first
                do {
                    if let bookmarkData = try url?.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil) {
                        let key = "bookmark:\(path)"
                        AppEnvironment.current.userDefaults.setData(for: key, bookmarkData)
                        
                        if self.resolveBookmark(bookmarkData, key: key) {
                            VenomLog.info("chosen \(url?.path ?? "")")
                            completion?(true)
                        } else {
                            VenomLog.error("error")
                        }
                    }
                    
                } catch {
                    VenomLog.error("error: \(error)")
                }
                
                
            case .cancel:
                VenomLog.error("User cancelled authorization.")
                
            default:
                break
            }
            
            completion?(false)
            
        })
    }
    
    
    
    private func resolveBookmark(_ bookmark: Data, key: String) -> Bool {
        var isStale = ObjCBool(false)
        
        do {
            let url = try NSURL(resolvingBookmarkData: bookmark, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
            if isStale.boolValue {
                VenomLog.info("Attempting to renew bookmark for \(url)")
                
                do {
                    let newBookmark = try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
                    AppEnvironment.current.userDefaults.setData(for: key, newBookmark)
                    return resolveBookmark(newBookmark, key: key)
                } catch {
                    VenomLog.error("Failed to renew bookmark: \(error)")
                }
            }
            
            if !url.startAccessingSecurityScopedResource() {
                VenomLog.error("startAccessingSecurityScopedResource failed")
                return false
            }
            
            
            VenomLog.info("Bookmarked url resolved successfully!")
            
            return true
            
        } catch {
            VenomLog.error("Error resolving URL from bookmark: \(error)")
        }
        
        return false
    }
}
