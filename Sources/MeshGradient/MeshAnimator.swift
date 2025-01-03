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
    
    /// - Parameters:
    ///   - framesPerSecond: Preferred framerate get that from MTKView
    ///   - animationSpeedRange: Range of animation duration in the mesh, literally. The less the faster
    ///   - meshRandomizer: Randomisation functions for mesh
    public struct Configuration {
        
        public var framesPerSecond: Int
        
        public var locationAnimationSpeedRange: ClosedRange<TimeInterval>
        public var tangentAnimationSpeedRange: ClosedRange<TimeInterval>
        public var colorAnimationSpeedRange: ClosedRange<TimeInterval>
        
        public var meshRandomizer: MeshRandomizer
        
        public init(
            framesPerSecond: Int = 60,
            locationAnimationSpeedRange: ClosedRange<TimeInterval> = 1...3,
            tangentAnimationSpeedRange: ClosedRange<TimeInterval> = 1...3,
            colorAnimationSpeedRange: ClosedRange<TimeInterval> = 0.1...0.2,
            meshRandomizer: MeshRandomizer
        ) {
            self.framesPerSecond = framesPerSecond
            self.locationAnimationSpeedRange = locationAnimationSpeedRange
            self.tangentAnimationSpeedRange = tangentAnimationSpeedRange
            self.colorAnimationSpeedRange = colorAnimationSpeedRange
            self.meshRandomizer = meshRandomizer
        }
    }

    private struct AnimationFrameControlPoint {
        // Location
        var finalLocation: simd_float2
        var startLocation: simd_float2
        var completionFactorLocation: Double
        var scaleFactorLocation: Double
        
        // UTangent
        var finalUTangent: simd_float2
        var startUTangent: simd_float2
        var completionFactorUTangent: Double
        var scaleFactorUTangent: Double
        
        // VTangent
        var finalVTangent: simd_float2
        var startVTangent: simd_float2
        var completionFactorVTangent: Double
        var scaleFactorVTangent: Double
        
        // Color
        var finalColor: simd_float3
        var startColor: simd_float3
        var completionFactorColor: Double
        var scaleFactorColor: Double
        
        mutating func bumpNextFrame() -> ControlPoint {
            
            let location = updateProperty2(
                startLocation,
                finalLocation,
                completionFactor: &completionFactorLocation,
                scaleFactor: scaleFactorLocation
            )
            
            let uTangent = updateProperty2(
                startUTangent,
                finalUTangent,
                completionFactor: &completionFactorUTangent,
                scaleFactor: scaleFactorUTangent
            )
            
            let vTangent = updateProperty2(
                startVTangent,
                finalVTangent,
                completionFactor: &completionFactorVTangent,
                scaleFactor: scaleFactorVTangent
            )
            
            let color = updateProperty3(
                startColor,
                finalColor,
                completionFactor: &completionFactorColor,
                scaleFactor: scaleFactorColor
            )
            
            return ControlPoint(color: color, location: location, uTangent: uTangent, vTangent: vTangent)
        }
        
        private func updateProperty2(
            _ start: SIMD2<Float>,
            _ end: SIMD2<Float>,
            completionFactor: inout Double,
            scaleFactor: Double
        ) -> SIMD2<Float> {
            completionFactor += scaleFactor
            if completionFactor > 1 {
                completionFactor = 1
            }
            var step = (end - start)
            let easedFactor = Float(completionFactor * completionFactor * (3 - 2 * completionFactor))
            step.scale(by: Double(easedFactor))
            return start + step
        }
        
        private func updateProperty3(
            _ start: SIMD3<Float>,
            _ end: SIMD3<Float>,
            completionFactor: inout Double,
            scaleFactor: Double
        ) -> SIMD3<Float> {
            completionFactor += scaleFactor
            if completionFactor > 1 {
                completionFactor = 1
            }
            var step = (end - start)
            let easedFactor = Float(completionFactor * completionFactor * (3 - 2 * completionFactor))
            step.scale(by: Double(easedFactor))
            return start + step
        }

        
        static var zero: AnimationFrameControlPoint {
            .init(
                finalLocation: .zero,
                startLocation: .zero,
                completionFactorLocation: 0,
                scaleFactorLocation: 0,
                
                finalUTangent: .zero,
                startUTangent: .zero,
                completionFactorUTangent: 0,
                scaleFactorUTangent: 0,
                
                finalVTangent: .zero,
                startVTangent: .zero,
                completionFactorVTangent: 0,
                scaleFactorVTangent: 0,
                
                finalColor: .zero,
                startColor: .zero,
                completionFactorColor: 0,
                scaleFactorColor: 0
            )
        }
    }

    // 插值扩展

    private let initialGrid: MeshGradientGrid<ControlPoint>
    public var configuration: Configuration
    private var animationParameters: MeshGradientGrid<AnimationFrameControlPoint>

    public init(grid: MeshGradientGrid<ControlPoint>, configuration: Configuration) {
        self.initialGrid = grid
        self.configuration = configuration

        self.animationParameters = MeshGradientGrid<AnimationFrameControlPoint>(repeating: .zero, width: grid.width, height: grid.height)

        for y in 0 ..< animationParameters.height {
            for x in 0 ..< animationParameters.width {
                let startPoint = grid[x, y]
                var animationFrame = AnimationFrameControlPoint.zero

                // Location
                let locationEndpoint = generateNextLocationEndpoint(x: x, y: y, gridWidth: grid.width, gridHeight: grid.height, startLocation: startPoint.location)
                animationFrame.finalLocation = locationEndpoint.final
                animationFrame.startLocation = startPoint.location
                animationFrame.scaleFactorLocation = locationEndpoint.scaleFactor

                // UTangent
                let uTangentEndpoint = generateNextTangentUEndpoint(x: x, y: y, gridWidth: grid.width, gridHeight: grid.height, startTangent: startPoint.uTangent)
                animationFrame.finalUTangent = uTangentEndpoint.final
                animationFrame.startUTangent = startPoint.uTangent
                animationFrame.scaleFactorUTangent = uTangentEndpoint.scaleFactor

                // VTangent
                let vTangentEndpoint = generateNextTangentVEndpoint(x: x, y: y, gridWidth: grid.width, gridHeight: grid.height, startTangent: startPoint.vTangent)
                animationFrame.finalVTangent = vTangentEndpoint.final
                animationFrame.startVTangent = startPoint.vTangent
                animationFrame.scaleFactorVTangent = vTangentEndpoint.scaleFactor

                // Color
                let colorEndpoint = generateNextColorEndpoint(x: x, y: y, gridWidth: grid.width, gridHeight: grid.height, startColor: startPoint.color)
                animationFrame.finalColor = colorEndpoint.final
                animationFrame.startColor = startPoint.color
                animationFrame.scaleFactorColor = colorEndpoint.scaleFactor

                animationParameters[x, y] = animationFrame
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
                var animationFrame = animationParameters[i]

                let updatedControlPoint = animationFrame.bumpNextFrame()
                resultGrid[i] = updatedControlPoint

                if animationFrame.completionFactorLocation >= 1 {
                    let newLocationEndpoint = generateNextLocationEndpoint(
                        x: x,
                        y: y,
                        gridWidth: resultGrid.width,
                        gridHeight: resultGrid.height,
                        startLocation: updatedControlPoint.location
                    )
                    animationFrame.finalLocation = newLocationEndpoint.final
                    animationFrame.startLocation = updatedControlPoint.location
                    animationFrame.completionFactorLocation = 0
                    animationFrame.scaleFactorLocation = newLocationEndpoint.scaleFactor
                }

                if animationFrame.completionFactorUTangent >= 1 {
                    let newUTangentEndpoint = generateNextTangentUEndpoint(
                        x: x,
                        y: y,
                        gridWidth: resultGrid.width,
                        gridHeight: resultGrid.height,
                        startTangent: updatedControlPoint.uTangent
                    )
                    animationFrame.finalUTangent = newUTangentEndpoint.final
                    animationFrame.startUTangent = updatedControlPoint.uTangent
                    animationFrame.completionFactorUTangent = 0
                    animationFrame.scaleFactorUTangent = newUTangentEndpoint.scaleFactor
                }

                if animationFrame.completionFactorVTangent >= 1 {
                    let newVTangentEndpoint = generateNextTangentVEndpoint(
                        x: x,
                        y: y,
                        gridWidth: resultGrid.width,
                        gridHeight: resultGrid.height,
                        startTangent: updatedControlPoint.vTangent
                    )
                    animationFrame.finalVTangent = newVTangentEndpoint.final
                    animationFrame.startVTangent = updatedControlPoint.vTangent
                    animationFrame.completionFactorVTangent = 0
                    animationFrame.scaleFactorVTangent = newVTangentEndpoint.scaleFactor
                }

                if animationFrame.completionFactorColor >= 1 {
                    let newColorEndpoint = generateNextColorEndpoint(
                        x: x,
                        y: y,
                        gridWidth: resultGrid.width,
                        gridHeight: resultGrid.height,
                        startColor: updatedControlPoint.color
                    )
                    animationFrame.finalColor = newColorEndpoint.final
                    animationFrame.startColor = updatedControlPoint.color
                    animationFrame.completionFactorColor = 0
                    animationFrame.scaleFactorColor = newColorEndpoint.scaleFactor
                }

                animationParameters[i] = animationFrame
            }
        }

        return resultGrid
    }

    private func generateNextLocationEndpoint(x: Int, y: Int, gridWidth: Int, gridHeight: Int, startLocation: simd_float2) -> (final: simd_float2, scaleFactor: Double) {
        let animationDuration = Double.random(in: configuration.locationAnimationSpeedRange)
        let scaleFactor = (1 / Double(configuration.framesPerSecond)) / animationDuration
        var randomizedControlPoint = initialGrid[x, y]

        //var newLocation = startLocation
        configuration.meshRandomizer.locationRandomizer(&randomizedControlPoint.location, x, y, gridWidth, gridHeight)

        return (final: randomizedControlPoint.location, scaleFactor: scaleFactor)
    }

    private func generateNextTangentUEndpoint(x: Int, y: Int, gridWidth: Int, gridHeight: Int, startTangent: simd_float2) -> (final: simd_float2, scaleFactor: Double) {
        let animationDuration = Double.random(in: configuration.tangentAnimationSpeedRange)
        let scaleFactor = (1 / Double(configuration.framesPerSecond)) / animationDuration
        var randomizedControlPoint = initialGrid[x, y]

       // var newTangent = startTangent
        configuration.meshRandomizer.turbulencyRandomizer(&randomizedControlPoint.uTangent, x, y, gridWidth, gridHeight)
       

        return (final: randomizedControlPoint.uTangent, scaleFactor: scaleFactor)
    }
    
    private func generateNextTangentVEndpoint(x: Int, y: Int, gridWidth: Int, gridHeight: Int, startTangent: simd_float2) -> (final: simd_float2, scaleFactor: Double) {
        let animationDuration = Double.random(in: configuration.tangentAnimationSpeedRange)
        let scaleFactor = (1 / Double(configuration.framesPerSecond)) / animationDuration
        var randomizedControlPoint = initialGrid[x, y]

       // var newTangent = startTangent
        configuration.meshRandomizer.turbulencyRandomizer(&randomizedControlPoint.vTangent, x, y, gridWidth, gridHeight)

        return (final: randomizedControlPoint.vTangent, scaleFactor: scaleFactor)
    }


    private func generateNextColorEndpoint(x: Int, y: Int, gridWidth: Int, gridHeight: Int, startColor: simd_float3) -> (final: simd_float3, scaleFactor: Double) {
        let animationDuration = Double.random(in: configuration.colorAnimationSpeedRange)
        let scaleFactor = (1 / Double(configuration.framesPerSecond)) / animationDuration
        var randomizedControlPoint = initialGrid[x, y]
//        var newColor = startColor
        configuration.meshRandomizer.colorRandomizer(&randomizedControlPoint.color, randomizedControlPoint.color, x, y, gridWidth, gridHeight)
        

        return (final: randomizedControlPoint.color, scaleFactor: scaleFactor)
    }
}
