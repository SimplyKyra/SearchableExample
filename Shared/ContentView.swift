//
//  ContentView.swift
//  Shared
//
//  Created by Kyra Delaney on 3/6/22.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) var moc
    
    
    @State var selection: Owner? = nil
    
    // Grab the current users
    @FetchRequest(entity: Owner.entity(), sortDescriptors: [
        NSSortDescriptor(keyPath: \Owner.name, ascending: true)
    ]) var owners: FetchedResults<Owner>
    
    
    var body: some View {
        NavigationView {
            List(selection: $selection)  {
                ForEach(owners, id: \.self) { owner in
                    NavigationLink(owner.name ?? "No name", tag: owner, selection: $selection, destination: {
                        ItemBrowseView(currOwner: owner)
                    })
                }
                // Swipe to delete - not seen in macOS
                .onDelete { indexSet in
                    withAnimation {
                        for offset in indexSet {
                            let owner = owners[offset]
                            moc.delete(owner)
                        }
                        // save the context
                        try? moc.save()
                    }
                }
            }

#if os(macOS)
            .onDeleteCommand {
                deleteOwnerBySelection()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.default, value: 1)
            .toolbar(content: {
                Button {
                    deleteOwnerBySelection()
                } label: {
                    Label("Delete Owner", systemImage: "trash.fill")
                }
                .keyboardShortcut(.delete, modifiers: [])
                .disabled(selection == nil)
                
                Button {
                    createNewOwner()
                } label: {
                    Label("Add an Owner", systemImage: "plus")
                }
            })
#else // iOS and iPAD
            .navigationTitle("Users")
            .navigationBarItems(trailing: HStack {
                Button(action: {
                    createNewOwner()
               }) {
                   Image(systemName: "plus")
                }})

#endif
        }
    }
    
    func deleteOwnerBySelection() {
        let sel = selection
        if sel != nil {
            print("deleting: \(sel!.name ?? "no name")")
            for item in sel!.items?.allObjects as! [Item] {
                moc.delete(item)
            }
            moc.delete(sel!)
            try? moc.save()
            
            if owners.count > 0 {
                selection = owners.first
            } else {
                selection = nil
            }
        }
    }
    
    
    
    func createNewOwner() {
        let newOwner = Owner(context: moc)
        newOwner.name = randomString(length: 10)
        try? moc.save()
    }
    
    func randomString(length: Int) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 "
      return String((0..<length).map{ _ in letters.randomElement()! })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
