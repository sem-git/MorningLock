//
//  AlarmQueue.swift
//  WakeUp
//
//  Created by a on 11/22/25.
//

import Foundation

enum QueueSortOption {
    case upcoming
    case test(testDate: Date)
    
    var sortClosure: (AlarmEntity, AlarmEntity) -> Bool {
        switch self {
        case .upcoming:
            return {
                let today = Calendar.current.component(.weekday, from: Date())
                
                let prev = $0.repeatDay.map { (weekDay: Weekday) -> Int in (weekDay.rawValue - today + 7) % 7}.min() ?? 0
                let next = $1.repeatDay.map { (weekDay: Weekday) -> Int in (weekDay.rawValue - today + 7) % 7 }.min() ?? 0
                
                // 오늘이랑 내일이 같지 않은 경우 오프셋 기준으로 정렬
                if prev != next {
                    return prev < next
                }
                // offset이 같으면 오늘 기준 시간 비교
                return $0.time.nextOccurrenceIncludingMinutes < $1.time.nextOccurrenceIncludingMinutes
            }
        case .test(let testDate):
            return {
                let today = Calendar.current.component(.weekday, from: testDate)
                
                let prev = $0.repeatDay.map { (weekDay: Weekday) -> Int in (weekDay.rawValue - today + 7) % 7}.min() ?? 0
                let next = $1.repeatDay.map { (weekDay: Weekday) -> Int in (weekDay.rawValue - today + 7) % 7 }.min() ?? 0
                
                // 오늘이랑 내일이 같지 않은 경우 오프셋 기준으로 정렬
                if prev != next {
                    return prev < next
                }
                // offset이 같으면 오늘 기준 시간 비교
                return $0.time.nextOccurrenceIncludingSeconds < $1.time.nextOccurrenceIncludingSeconds
            }
        }
    }
}

struct AlarmQueue {
    private var heap: Heap<AlarmEntity>!
    
    init(sort option: QueueSortOption) {
        self.heap = Heap(sort: option.sortClosure)
    }
    
    mutating func insert(_ alarm: AlarmEntity) {
        heap.insert(alarm)
    }
    
    mutating func delete() -> AlarmEntity? {
        heap.delete()
    }
    
    func peek() -> AlarmEntity? {
        heap.peek()
    }
}

struct Heap<T: Comparable> {
    
    private var elements: [T] = []
    private var sort: (T, T) -> Bool
    
    init(sort: @escaping (T, T) -> Bool) {
        self.sort = sort
    }
    
    func peek() -> T? {
        if elements.isEmpty {
            return nil
        }
        return self.elements[1]
    }
    
    mutating func insert(_ value: T) {
        if elements.isEmpty {
            elements.append(value)
        }
        elements.append(value)
        var currentIndex = elements.count - 1
        
        while currentIndex > 1 {
            let parentIndex = Int(currentIndex / 2)
            if sort(elements[currentIndex], elements[parentIndex]) {
                elements.swapAt(currentIndex, parentIndex)
                currentIndex = parentIndex
            } else {
                break
            }
        }
    }
    
    mutating func delete() -> T? {
        if elements.count <= 1 {
            return nil
        }
        elements.swapAt(1, elements.count - 1)
        let maxElement = elements.removeLast()
        var currentIndex = 1
        
        while currentIndex <= (elements.count - 1) {
            let leftChildIndex = 2 * currentIndex
            let rightChildIndex = 2 * currentIndex + 1
            var maxIndex = currentIndex
            
            if leftChildIndex <= elements.count - 1 && sort(elements[leftChildIndex], elements[maxIndex]) {
                maxIndex = leftChildIndex
            }
            if rightChildIndex <= elements.count - 1 && sort(elements[rightChildIndex], elements[maxIndex]) {
                maxIndex = rightChildIndex
            }
            
            if currentIndex == maxIndex {
                break
            }
            
            elements.swapAt(maxIndex, currentIndex)
            currentIndex = maxIndex
        }
        
        return maxElement
    }
}
