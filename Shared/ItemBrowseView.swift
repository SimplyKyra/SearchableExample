//
//  ItemBrowseView.swift
//  FilteringExample
//
//  Created by Kyra Delaney on 3/7/22.
//

import SwiftUI

struct ItemBrowseView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State var owner:Owner?
    
    // macOS Delete a template by selection
    @State var selection: Item? = nil
    
    // Data
    // Allow for sections
    var sectionedFetchRequest = SectionedFetchRequest(
        sectionIdentifier: ItemSort.default.section,
        sortDescriptors: ItemSort.default.descriptors,
        predicate: NSPredicate(format: "owner == nil"),
        animation: .default
    )
    private var items: SectionedFetchResults<String, Item> { sectionedFetchRequest.wrappedValue }
    @State private var selectedSort = ItemSort.default
    
    // searchable
    @State private var searchTerm = ""
    var searchQuery: Binding<String> {
        Binding {
            searchTerm
        } set: { newValue in
            searchTerm = newValue
            guard !newValue.isEmpty else {
                items.nsPredicate = nil
                return
            }
            items.nsPredicate = NSPredicate(
                format: "name contains[cd] %@",
                newValue)
        }
    }
    
    init(currOwner:Owner?) {
        print("Initializing")
        print(currOwner?.name ?? "No name")
        owner = currOwner
        
        if owner == nil {
            sectionedFetchRequest = SectionedFetchRequest(
                sectionIdentifier: ItemSort.default.section,
                sortDescriptors: ItemSort.default.descriptors,
                predicate: NSPredicate(format: "owner == nil"),
                animation: .default
            )
        } else {
            sectionedFetchRequest = SectionedFetchRequest(
                sectionIdentifier: ItemSort.default.section,
                sortDescriptors: ItemSort.default.descriptors,
                predicate: NSPredicate(format: "owner == %@", owner!),
                animation: .default
            )
        }
    }
    
    var body: some View {
        NavigationView {
            Text(owner?.name ?? "No name")
            List(selection: $selection) {
                ForEach(items) { section in
                    Section(header: Text(section.id)) {
                        ForEach(section) { item in
                            NavigationLink(
                                destination: ItemDetail(owner: item.owner, item:item, editingState: .edit),
                                tag: item,
                                selection: $selection) {
                                VStack {
                                    Text(item.name ?? "No name")
                                    Text(item.created!, formatter: itemFormatter)
                                }
                            }
                        }
                        // Swipe to delete - not seen in macOS
                        .onDelete { indexSet in
                            withAnimation {
                                for offset in indexSet {
                                    let item = section[offset]
                                    viewContext.delete(item)
                                }
                                // save the context
                                try? viewContext.save()
                            }
                        }
                    }
#if os(macOS)
                    .onDeleteCommand(perform: {
                        deleteItemBySelection()
                    })
#endif
                }
            }
            .searchable(text: searchQuery)
            .toolbar {
#if os(macOS)
                ToolbarItemGroup(content: {
                    Button {
                        print("Deleting!")
                        deleteItemBySelection()
                    } label: {
                        Image(systemName: "trash")
                    }
                    
                    Button {
                        addItem()
                    } label: {
                        Image(systemName: "plus")
                    }
                    
                    ItemSortSelectionView(
                      selectedSortItem: $selectedSort,
                      sorts: ItemSort.sorts)
                    .onChange(of: selectedSort) { newValue in
                        print("In selected sort change: \(newValue.name)")
                      let request = items
                      request.sortDescriptors = selectedSort.descriptors
                      request.sectionIdentifier = selectedSort.section
                    }
                })
    #else
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                ItemSortSelectionView(
                  selectedSortItem: $selectedSort,
                  sorts: ItemSort.sorts)
                .onChange(of: selectedSort) { newValue in
                    print("Changing predicates now: \(newValue.name)")
                    let request = items
                    request.sortDescriptors = selectedSort.descriptors
                    request.sectionIdentifier = selectedSort.section
                }
                
                Button(action: {
                    addItem()
                }) {
                    Image(systemName: "plus")
                }
            }
    #endif
        }
        }
    }

    func deleteItemBySelection() {
        let sel = selection
        if sel != nil {
            print("deleting: \(sel!.name ?? "no name")")
            viewContext.delete(sel!)
            try? viewContext.save()
            
            if items.count > 0 {
                selection = getFirstItem()
            } else {
                selection = nil
            }
        }
    }
    
    func getFirstItem() -> Item? {
        for section in items {
            for item in section {
                return item
            }
        }
        return nil
    }
    
    func addItem() {
        if owner == nil {
            print("No owner!")
            return
        }
        let newItem = Item(context: viewContext)
        newItem.name = randomString(length: 10)
        newItem.details = randomString(length: 100)
        newItem.lastUpdated = Date()
        newItem.created = Date()
        newItem.owner = owner
        try? viewContext.save()
    }
    
    func randomString(length: Int) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 "
      return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()


//struct ItemBrowseView_Previews: PreviewProvider {
//    static var previews: some View {
//        ItemBrowseView()
//    }
//}
