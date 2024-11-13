import Foundation
import SwiftUI
import simd
import Accelerate

/// A two-dimensional grid of `Element`.
public struct MeshGradientGrid<Element> {
    public var elements: ContiguousArray<Element>

    public var width: Int

    public var height: Int

    public init(repeating element: Element, width: Int, height: Int) {
        self.width = width
        self.height = height
        self.elements = ContiguousArray(repeating: element, count: width * height)
    }
	
	public init(width: Int, array: () -> [Element]) {
		let arr = array()
		assert(arr.count.isMultiple(of: width))
		self.width = width
		self.height = arr.count / width
		self.elements = ContiguousArray(arr)
	}
	
	public func index(x: Int, y: Int) -> Int {
		x + y * width
	}
	
	public subscript(i: Int) -> Element {
		get {
			elements[i]
		}
		set {
			elements[i] = newValue
		}
	}
	
	public subscript(x: Int, y: Int) -> Element {
		get {
			self[index(x: x, y: y)]
		}
		set {
			self[index(x: x, y: y)] = newValue
		}
	}
}

extension MeshGradientGrid: Equatable where Element: Equatable {}
extension MeshGradientGrid: Hashable where Element: Hashable {}

extension Collection {
    
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension MeshGradientGrid: VectorArithmetic, AdditiveArithmetic where Element: VectorArithmetic & AdditiveArithmetic {
    public static func - (lhs: MeshGradientGrid<Element>, rhs: MeshGradientGrid<Element>) -> MeshGradientGrid<Element> {
        var grid = MeshGradientGrid(repeating: .zero, width: lhs.width, height: lhs.height)
        for i in lhs.elements.indices {
            grid.elements[i] = lhs.elements[i] - (rhs.elements[safe: i] ?? Element.zero)
        }
        return grid
    }
    
    public static func + (lhs: MeshGradientGrid<Element>, rhs: MeshGradientGrid<Element>) -> MeshGradientGrid<Element> {
        var grid = MeshGradientGrid(repeating: .zero, width: lhs.width, height: lhs.height)
        
        for i in lhs.elements.indices {
            grid.elements[i] = lhs.elements[i] + (rhs.elements[safe: i] ?? Element.zero)
        }
        return grid
    }
    
    public mutating func scale(by rhs: Double) {
        for i in elements.indices {
            elements[i].scale(by: rhs)
        }
    }
    
    public var magnitudeSquared: Double {
        elements.reduce(0, { $0 + Double($1.magnitudeSquared) })
    }
    
    public static var zero: MeshGradientGrid<Element> {
        .init(repeating: Element.zero, width: 0, height: 0)
    }
}

extension SIMD2: VectorArithmetic, AdditiveArithmetic where Scalar == Float {
    public mutating func scale(by rhs: Double) {
        self = self * SIMD2<Scalar>(x: Float(rhs), y: Float(rhs))
    }
    
    public var magnitudeSquared: Double {
        Double(x*x + y*y)
    }
}

extension SIMD3: VectorArithmetic, AdditiveArithmetic where Scalar == Float {
    public mutating func scale(by rhs: Double) {
        self = self * SIMD3<Scalar>(x: Float(rhs), y: Float(rhs), z: Float(rhs))
    }
    
    public var magnitudeSquared: Double {
        Double(x*x+y*y+z*z)
    }
}
