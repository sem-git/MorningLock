//
//  CoreDataManager.swift
//  WakeUp
//
//  Created by a on 10/18/25.
//

import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() { }
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Alarm")
        
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Failed to load persistent stores: \(error.localizedDescription)")
            }
        }
        return container
    }()
    
    lazy var context = persistentContainer.viewContext
    
    func addAlarm(alarm: AlarmEntity) async throws {
        let newAlarm = Alarm(context: context)
        newAlarm.id = alarm.id
        newAlarm.isActive = alarm.isActive
        newAlarm.fireDate = alarm.fireDate
        newAlarm.repeatDay = alarm.repeatDay.map { $0.rawValue }
        
        do {
            try context.save()
            print("데이터 추가 성공")
        } catch {
            throw error
        }
    }
    
    func fetchAlarm() -> [Alarm] {
        context.performAndWait {
            let request: NSFetchRequest<Alarm> = Alarm.fetchRequest()
            
            do {
                let result = try context.fetch(request)
                return result
            } catch {
                print("Fetch request error: \(error)")
            }
            return []
        }
    }
    
    func updateAlarm(alarm: AlarmEntity) throws {
        let request: NSFetchRequest<Alarm> = Alarm.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", alarm.id as CVarArg)
        
        context.performAndWait {
            do {
                let data = try context.fetch(request)
                
                if var updateAlarm = data.first {
                    updateAlarm.isActive = alarm.isActive
                    updateAlarm.fireDate = alarm.fireDate
                    updateAlarm.repeatDay = alarm.repeatDay.map(\.rawValue)
                    try context.save()
                }
            } catch {
                print("Update error: \(error)")
            }
        }
    }
    
    func deleteAlarm(id: UUID) {
        let request: NSFetchRequest<Alarm> = Alarm.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        context.performAndWait {
            do {
                let data = try context.fetch(request)
                
                guard let deleteAlarm = data.first else {
                    return
                }
            
                context.delete(deleteAlarm)
                try context.save()
            } catch {
                print("Delete error: \(error)")
            }
        }
    }
}
