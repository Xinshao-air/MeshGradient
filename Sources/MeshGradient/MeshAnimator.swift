/*
import Foundation
import simd

/// Stores current and next state of the mesh. Used for animatable meshes
public final class MeshAnimator: MeshDataProvider {
    
	public struct Configuration {
		
		/// - Parameters:
		///   - framesPerSecond: Preferred framerate get that from MTKView
		///   - animationSpeedRange: Range of animation duration in the mesh, literally. The less the faster
		///   - meshRandomizer: Randomisation functions for mesh
		public init(framesPerSecond: Int = 60, animationSpeedRange: ClosedRange<TimeInterval> = 2...5, meshRandomizer: MeshRandomizer) {
			self.framesPerSecond = framesPerSecond
			self.animationSpeedRange = animationSpeedRange
			self.meshRandomizer = meshRandomizer
		}
		
		public var framesPerSecond: Int
		public var animationSpeedRange: ClosedRange<TimeInterval>
		public var meshRandomizer: MeshRandomizer
	}

    private struct AnimationFrameControlPoint {
        let finalControlPoint: ControlPoint
        let startPoint: ControlPoint
        var completionFactor: Double // 0...1
        let scaleFactor: Double
        
        mutating func bumpNextFrame() -> ControlPoint {
            completionFactor += scaleFactor
            var step = (finalControlPoint - startPoint)
            
            let easedCompletionFactor = completionFactor * completionFactor * (3 - 2 * completionFactor);
            step.scale(by: easedCompletionFactor)
            
            return startPoint + step
        }
        
        static var zero: AnimationFrameControlPoint {
            .init(finalControlPoint: .zero, startPoint: .zero, completionFactor: .zero, scaleFactor: .zero)
        }
    }
    
	private let initialGrid: MeshGradientGrid<ControlPoint>
    public var configuration: Configuration
	private var animationParameters: MeshGradientGrid<AnimationFrameControlPoint>
    
	public init(grid: MeshGradientGrid<ControlPoint>, configuration: Configuration) {
        self.initialGrid = grid
        self.configuration = configuration
        
        self.animationParameters = MeshGradientGrid<AnimationFrameControlPoint>(repeating: .zero, width: grid.width, height: grid.height)
        
        for y in 0 ..< animationParameters.height {
            for x in 0 ..< animationParameters.width {
				animationParameters[x, y] = generateNextAnimationEndpoint(x: x, y: y, gridWidth: grid.width, gridHeight: grid.height, startPoint: grid[x, y])
            }
        }
    }
    
    public var grid: MeshGradientGrid<ControlPoint> {
        var resultGrid = MeshGradientGrid<ControlPoint>(repeating: .zero,
                                            width: animationParameters.width,
                                            height: animationParameters.height)
        
        for y in 0 ..< animationParameters.height {
            for x in 0 ..< animationParameters.width {
                let i = animationParameters.index(x: x, y: y)
                resultGrid[i] = animationParameters[i].bumpNextFrame()
                if animationParameters[i].completionFactor >= 1 {
					animationParameters[i] = generateNextAnimationEndpoint(x: x, y: y, gridWidth: resultGrid.width, gridHeight: resultGrid.height, startPoint: resultGrid[i])
                }
            }
        }
        return resultGrid
    }
    
	private func generateNextAnimationEndpoint(x: Int, y: Int, gridWidth: Int, gridHeight: Int, startPoint: ControlPoint) -> AnimationFrameControlPoint {
		let animationDuration = Double.random(in: configuration.animationSpeedRange)
        let scaleFactor = (1 / Double(configuration.framesPerSecond)) / animationDuration
        var randomizedControlPoint = initialGrid[x, y]
        
		configuration.meshRandomizer.locationRandomizer(&randomizedControlPoint.location, x, y, gridWidth, gridHeight)
		
		configuration.meshRandomizer.turbulencyRandomizer(&randomizedControlPoint.uTangent, x, y, gridWidth, gridHeight)
		configuration.meshRandomizer.turbulencyRandomizer(&randomizedControlPoint.vTangent, x, y, gridWidth, gridHeight)
		
		configuration.meshRandomizer.colorRandomizer(&randomizedControlPoint.color, randomizedControlPoint.color, x, y, gridWidth, gridHeight)
        
        return AnimationFrameControlPoint(finalControlPoint: randomizedControlPoint,
                                          startPoint: startPoint,
                                          completionFactor: 0,
                                          scaleFactor: scaleFactor)
    }
    
}
*/

import Foundation
import simd

/// Stores current and next state of the mesh. Used for animatable meshes
public final class MeshAnimator: MeshDataProvider {
    
    public struct Configuration {
        
        /// - Parameters:
        ///   - framesPerSecond: Preferred framerate get that from MTKView
        ///   - locationAnimationSpeedRange: Range of animation duration for location
        ///   - turbulencyAnimationSpeedRange: Range of animation duration for turbulency
        ///   - colorAnimationSpeedRange: Range of animation duration for color
        ///   - meshRandomizer: Randomisation functions for mesh
        public init(
            framesPerSecond: Int = 60,
            locationAnimationSpeedRange: ClosedRange<TimeInterval> = 2...5,
            turbulencyAnimationSpeedRange: ClosedRange<TimeInterval> = 2...5,
            colorAnimationSpeedRange: ClosedRange<TimeInterval> = 2...5,
            meshRandomizer: MeshRandomizer
        ) {
            self.framesPerSecond = framesPerSecond
            self.locationAnimationSpeedRange = locationAnimationSpeedRange
            self.turbulencyAnimationSpeedRange = turbulencyAnimationSpeedRange
            self.colorAnimationSpeedRange = colorAnimationSpeedRange
            self.meshRandomizer = meshRandomizer
        }
        
        public var framesPerSecond: Int
        public var locationAnimationSpeedRange: ClosedRange<TimeInterval>
        public var turbulencyAnimationSpeedRange: ClosedRange<TimeInterval>
        public var colorAnimationSpeedRange: ClosedRange<TimeInterval>
        public var meshRandomizer: MeshRandomizer
    }

    private struct AnimationFrameControlPoint {
        let finalControlPoint: ControlPoint
        let startPoint: ControlPoint
        var locationCompletion: Double // 0...1
        var locationScale: Double
        var uTangentCompletion: Double // 0...1
        var uTangentScale: Double
        var vTangentCompletion: Double // 0...1
        var vTangentScale: Double
        var colorCompletion: Double // 0...1
        var colorScale: Double
        
        mutating func bumpNextFrame() -> ControlPoint {
            var newControlPoint = startPoint
            
            // Update location
            if locationCompletion < 1 {
                locationCompletion += locationScale
                let easedLocation = locationCompletion * locationCompletion * (3 - 2 * locationCompletion)
                var step = (finalControlPoint.location - startPoint.location)
                step *= Float(easedLocation)
                newControlPoint.location = startPoint.location + step
            } else {
                newControlPoint.location = finalControlPoint.location
            }
            
            // Update uTangent
            if uTangentCompletion < 1 {
                uTangentCompletion += uTangentScale
                let easedUTangent = uTangentCompletion * uTangentCompletion * (3 - 2 * uTangentCompletion)
                var step = (finalControlPoint.uTangent - startPoint.uTangent)
                step *= Float(easedUTangent)
                newControlPoint.uTangent = startPoint.uTangent + step
            } else {
                newControlPoint.uTangent = finalControlPoint.uTangent
            }
            
            // Update vTangent
            if vTangentCompletion < 1 {
                vTangentCompletion += vTangentScale
                let easedVTangent = vTangentCompletion * vTangentCompletion * (3 - 2 * vTangentCompletion)
                var step = (finalControlPoint.vTangent - startPoint.vTangent)
                step *= Float(easedVTangent)
                newControlPoint.vTangent = startPoint.vTangent + step
            } else {
                newControlPoint.vTangent = finalControlPoint.vTangent
            }
            
            // Update color
            if colorCompletion < 1 {
                colorCompletion += colorScale
                let easedColor = colorCompletion * colorCompletion * (3 - 2 * colorCompletion)
                var step = (finalControlPoint.color - startPoint.color)
                step *= Float(easedColor)
                newControlPoint.color = startPoint.color + step
            } else {
                newControlPoint.color = finalControlPoint.color
            }
            
            return newControlPoint
        }
        
        static var zero: AnimationFrameControlPoint {
            .init(
                finalControlPoint: .zero,
                startPoint: .zero,
                locationCompletion: 0,
                locationScale: 0,
                uTangentCompletion: 0,
                uTangentScale: 0,
                vTangentCompletion: 0,
                vTangentScale: 0,
                colorCompletion: 0,
                colorScale: 0
            )
        }
    }
    
    private let initialGrid: MeshGradientGrid<ControlPoint>
    public var configuration: Configuration
    private var animationParameters: MeshGradientGrid<AnimationFrameControlPoint>
    
    public init(grid: MeshGradientGrid<ControlPoint>, configuration: Configuration) {
        self.initialGrid = grid
        self.configuration = configuration
        
        self.animationParameters = MeshGradientGrid<AnimationFrameControlPoint>(
            repeating: .zero,
            width: grid.width,
            height: grid.height
        )
        
        for y in 0..<animationParameters.height {
            for x in 0..<animationParameters.width {
                animationParameters[x, y] = generateNextAnimationEndpoint(x: x, y: y, gridWidth: grid.width, gridHeight: grid.height, startPoint: grid[x, y])
            }
        }
    }
    
    public var grid: MeshGradientGrid<ControlPoint> {
        var resultGrid = MeshGradientGrid<ControlPoint>(
            repeating: .zero,
            width: animationParameters.width,
            height: animationParameters.height
        )
        
        for y in 0..<animationParameters.height {
            for x in 0..<animationParameters.width {
                let i = animationParameters.index(x: x, y: y)
                resultGrid[i] = animationParameters[i].bumpNextFrame()
                
                // Check if any of the animations are complete
                if animationParameters[i].locationCompletion >= 1 ||
                    animationParameters[i].uTangentCompletion >= 1 ||
                    animationParameters[i].vTangentCompletion >= 1 ||
                    animationParameters[i].colorCompletion >= 1 {
                    
                    animationParameters[i] = generateNextAnimationEndpoint(
                        x: x,
                        y: y,
                        gridWidth: resultGrid.width,
                        gridHeight: resultGrid.height,
                        startPoint: resultGrid[i]
                    )
                }
            }
        }
        return resultGrid
    }
    
    private func generateNextAnimationEndpoint(x: Int, y: Int, gridWidth: Int, gridHeight: Int, startPoint: ControlPoint) -> AnimationFrameControlPoint {
        let locationDuration = Double.random(in: configuration.locationAnimationSpeedRange)
        let turbulencyDuration = Double.random(in: configuration.turbulencyAnimationSpeedRange)
        let colorDuration = Double.random(in: configuration.colorAnimationSpeedRange)
        
        let locationScale = (1 / Double(configuration.framesPerSecond)) / locationDuration
        let turbulencyScale = (1 / Double(configuration.framesPerSecond)) / turbulencyDuration
        let colorScale = (1 / Double(configuration.framesPerSecond)) / colorDuration
        
        var randomizedControlPoint = initialGrid[x, y]
        
        configuration.meshRandomizer.locationRandomizer(&randomizedControlPoint.location, x, y, gridWidth, gridHeight)
        
        configuration.meshRandomizer.turbulencyRandomizer(&randomizedControlPoint.uTangent, x, y, gridWidth, gridHeight)
        configuration.meshRandomizer.turbulencyRandomizer(&randomizedControlPoint.vTangent, x, y, gridWidth, gridHeight)
        
        configuration.meshRandomizer.colorRandomizer(&randomizedControlPoint.color, randomizedControlPoint.color, x, y, gridWidth, gridHeight)
        
        return AnimationFrameControlPoint(
            finalControlPoint: randomizedControlPoint,
            startPoint: startPoint,
            locationCompletion: 0,
            locationScale: locationScale,
            uTangentCompletion: 0,
            uTangentScale: turbulencyScale,
            vTangentCompletion: 0,
            vTangentScale: turbulencyScale,
            colorCompletion: 0,
            colorScale: colorScale
        )
    }
}

