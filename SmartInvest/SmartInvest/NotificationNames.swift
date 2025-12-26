//
//  NotificationNames.swift
//  SmartInvest
//
//  Central place for all custom Notification.Name extensions
//

import Foundation

extension Notification.Name {
    /// Sent when user successfully logs out (or on error)
    static let userDidLogout = Notification.Name("userDidLogout")
    static let userDidAuthenticate = Notification.Name("userDidAuthenticate")
    // You can add more custom notifications here later
    // static let newPredictionSaved = Notification.Name("newPredictionSaved")
}
