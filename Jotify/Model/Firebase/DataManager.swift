//
//  DataManager.swift
//  Zurich
//
//  Created by Harrison Leath on 1/12/21.
//

import FirebaseFirestore

class DataManager {
    
    //create user settings in cloud
    static func createUserSettings(completionHandler: @escaping (Bool?) -> Void) {
        if AuthManager().uid.isEmpty { return }
        let db = Firestore.firestore()
        db.collection("users").document(AuthManager().uid).setData([
            "multilineInputEnabled": false,
            "deleteOldNotes": false,
            "useHaptics": true,
            "useBiometrics": false,
            "placeholder": "Tap to start typing or swipe left to right for saved notes...",
            "hasMigrated": false,
            "defaultView": 0,
            "referrals": 0,
            "referralLink": "",
            "hasPremium": false
        ]) { (error) in
            if let error = error {
                print("Error deleting document: \(error.localizedDescription)")
                completionHandler(false)
            } else {
                print("User settings created successfully")
                completionHandler(true)
            }
        }
    }
    
    //reads the user settings in users -> user uid (fields)
    static func retrieveUserSettings(completionHandler: @escaping (Settings?, Bool?) -> Void) {
        if AuthManager().uid.isEmpty { return }
        let db = Firestore.firestore()
        db.collection("users").document(AuthManager().uid).getDocument { (snapshot, error) in
            if let error = error {
                print("Error retrieving document: \(error.localizedDescription)")
                completionHandler(nil, false)
            } else {
                print("Firebase settings retrieved")
                let settings = Settings(
                    multilineInputEnabled: snapshot?.get("multilineInputEnabled") as? Bool ?? false,
                    deleteOldNotes: snapshot?.get("deleteOldNotes") as? Bool ?? false,
                    useHaptics: snapshot?.get("useHaptics") as? Bool ?? true,
                    useBiometrics: snapshot?.get("useBiometrics") as? Bool ?? false,
                    placeholder: snapshot?.get("placeholder") as? String ?? "Tap to start typing or swipe left to right for saved notes...",
                    defaultView: snapshot?.get("defaultView") as? Int ?? 0,
                    hasMigrated: snapshot?.get("hasMigrated") as? Bool ?? false,
                    referrals: snapshot?.get("referrals") as? Int ?? 0,
                    referralLink: snapshot?.get("referralLink") as? String ?? "",
                    hasPremium: snapshot?.get("hasPremium") as? Bool ?? false)
                completionHandler(settings, true)
            }
        }
    }
    
    //update the given setting with a value
    static func updateUserSettings(setting: String, value: Any, completionHandler: @escaping (Bool?) -> Void) {
        if AuthManager().uid.isEmpty { return }
        let db = Firestore.firestore()
        db.collection("users").document(AuthManager().uid).updateData([
            setting: value,
        ]) { error in
            if let error = error {
                print("Error adding document: \(error)")
                completionHandler(false)
            }
            completionHandler(true)
        }
    }
    
    //delete setting document attributed to currently logged in user
    static func deleteUserSettings(completionHandler: @escaping (Bool?) -> Void) {
        if AuthManager().uid.isEmpty { return }
        let db = Firestore.firestore()
        db.collection("users").document(AuthManager().uid).delete { (error) in
            if let error = error {
                print("Error deleting document: \(error.localizedDescription)")
                completionHandler(false)
            } else {
                completionHandler(true)
            }
        }
    }
    
    //create note document with 2 fields, timestamp and content
    //returns documentID so doc can be updated immediately...
    @discardableResult static func createNote(content: String, timestamp: Double, color: String) -> String {
        if AuthManager().uid.isEmpty { return ""}
        let db = Firestore.firestore()
        var ref: DocumentReference? = nil
        ref = db.collection("notes").document(AuthManager().uid).collection("userNotes").addDocument(data: [
            "content": content,
            "timestamp": timestamp,
            "color": color
        ]) { error in
            if let error = error {
                print("Error adding document: \(error)")
            } else {
                print("Document added with ID: \(ref!.documentID)")
            }
        }
        return ref?.documentID ?? ""
    }
    
    //update the content (and timestamp) of a single document
    static func updateNoteContent(content: String, uid: String, completionHandler: @escaping (Bool?) -> Void) {
        if AuthManager().uid.isEmpty { return }
        let db = Firestore.firestore()
        db.collection("notes").document(AuthManager().uid).collection("userNotes").document(uid).updateData([
            "content": content,
            "timestamp": Date.timeIntervalSinceReferenceDate,
        ]) { error in
            if let error = error {
                print("Error adding document: \(error)")
                completionHandler(false)
            }
            completionHandler(true)
        }
    }
    
    //update color of a single document
    static func updateNoteColor(color: String, uid: String, completionHandler: @escaping (Bool?) -> Void) {
        if AuthManager().uid.isEmpty { return }
        let db = Firestore.firestore()
        db.collection("notes").document(AuthManager().uid).collection("userNotes").document(uid).updateData([
            "color": color,
        ]) { error in
            if let error = error {
                print("Error adding document: \(error)")
                completionHandler(false)
            }
            completionHandler(true)
        }
    }
    
    //update the value of reminder for note with uid
    static func updateNoteReminder(reminder: String, reminderTimestamp: Double, uid: String, completionHandler: @escaping (Bool?) -> Void) {
        if AuthManager().uid.isEmpty { return }
        let db = Firestore.firestore()
        db.collection("notes").document(AuthManager().uid).collection("userNotes").document(uid).updateData([
            "reminder": reminder,
            "reminderTimestamp": reminderTimestamp
        ]) { error in
            if let error = error {
                print("Error adding document: \(error)")
                completionHandler(false)
            }
            completionHandler(true)
        }
    }
    
    static func removeReminder(uid: String, completionHandler: @escaping (Bool?) -> Void) {
        if AuthManager().uid.isEmpty { return }
        let db = Firestore.firestore()
        db.collection("notes").document(AuthManager().uid).collection("userNotes").document(uid).updateData([
            "reminder": FieldValue.delete(),
            "reminderTimestamp": FieldValue.delete()
        ]) { error in
            if let error = error {
                print("Error adding document: \(error)")
                completionHandler(false)
            }
            completionHandler(true)
        }
    }

    
    //observe data change in notes -> user uid -> collection userNotes, and retrieve all notes in userNotes
    static func observeNoteChange(completionHandler: @escaping (NoteCollection?, Bool?) -> Void) {
        if AuthManager().uid.isEmpty { return }
        let db = Firestore.firestore()
        let collection = NoteCollection()
        db.collection("notes").document(AuthManager().uid).collection("userNotes").order(by: "timestamp", descending: false).addSnapshotListener { (snapshot, error) in
            guard let snapshot = snapshot else {
                print("Error fetching snapshots: \(error!)")
                completionHandler(nil, false)
                return
            }
            snapshot.documentChanges.forEach { diff in
                let content = diff.document.get("content") as? String ?? ""
                let timestamp = diff.document.get("timestamp") as? Double ?? 0
                let id = diff.document.documentID
                let color = diff.document.get("color") as? String ?? ""
                let reminder = diff.document.get("reminder") as? String ?? ""
                let reminderTimestamp = diff.document.get("reminderTimestamp") as? Double ?? 0
                let note = FBNote(content: content, timestamp: timestamp, id: id, color: color, reminder: reminder, reminderTimestamp: reminderTimestamp)
                
                if (diff.type == .added) {
//                    print("New note: \(diff.document.data())")
                    collection.FBNotes.insert(note, at: 0)
                }
                
                if (diff.type == .modified) {
//                    print("Modified note: \(diff.document.data())")
                    if let noteIndex = collection.FBNotes.firstIndex(where: { $0.id == id}) {
                        collection.FBNotes.remove(at: noteIndex)
                        //could also just append to array normally since array is sorted below
                        collection.FBNotes.insert(note, at: 0)
                    }
                    collection.FBNotes.sort { ($0.timestamp) > ($1.timestamp) }
                }
                
                if (diff.type == .removed) {
//                    print("Removed note: \(diff.document.data())")
                    collection.FBNotes = collection.FBNotes.filter {$0.id != diff.document.documentID }
                }
                
                completionHandler(collection, true)
            }
        }
    }
    
    //delete note document based on the documentID
    static func deleteNote(docID: String, completionHandler: @escaping (Bool?) -> Void) {
        if AuthManager().uid.isEmpty { return }
        let db = Firestore.firestore()
        db.collection("notes").document(AuthManager().uid).collection("userNotes").document(docID).delete { (error) in
            if let error = error {
                print("Error deleting document: \(error.localizedDescription)")
                completionHandler(false)
            } else {
                completionHandler(true)
            }
        }
    }
}
