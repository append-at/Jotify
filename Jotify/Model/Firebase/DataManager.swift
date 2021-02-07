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
            "colorScheme": "white",
        ]) { (error) in
            if let error = error {
                print("Error deleting document: \(error.localizedDescription)")
                completionHandler(false)
            } else {
                completionHandler(true)
            }
        }
    }
    
    //reads the user settings in users -> user uid (fields)
    static func retrieveUserSettings(completetionHandler: @escaping (Bool?) -> Void) {
        if AuthManager().uid.isEmpty { return }
        let db = Firestore.firestore()
        db.collection("users").document(AuthManager().uid).getDocument { (snapshot, error) in
            //do something with data retrieved
        }
    }
    
    //create note document with 2 fields, timestamp and content
    //returns documentID so doc can be updated immediately...
    static func createNote(content: String, timestamp: Double, color: String) -> String {
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
    
    //update the content of a single document
    static func updateNote(content: String, uid: String, completionHandler: @escaping (Bool?) -> Void) {
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
                let uid = diff.document.documentID
                let color = diff.document.get("color") as? String ?? ""
                let note = Note(content: content, timestamp: timestamp, uid: uid, color: color)
                
                if (diff.type == .added) {
//                    print("New note: \(diff.document.data())")
                    collection.notes.insert(note, at: 0)
                    
                }
                if (diff.type == .modified) {
                    print("Modified note: \(diff.document.data())")
                    if let noteIndex = collection.notes.firstIndex(where: { $0.uid == uid}) {
                        collection.notes.remove(at: noteIndex)
                        //could also just append to array normally since array is sorted below
                        collection.notes.insert(note, at: 0)
                    }
                    collection.notes.sort { ($0.timestamp) > ($1.timestamp) }
                }
                if (diff.type == .removed) {
                    print("Removed note: \(diff.document.data())")
                    collection.notes = collection.notes.filter {$0.uid != diff.document.documentID }
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
                print("Error deleting document: \(error)")
                completionHandler(false)
            } else {
                completionHandler(true)
            }
        }
    }
}