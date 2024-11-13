
public protocol MeshDataProvider {
	var grid: MeshGradientGrid<ControlPoint> { get }
}

public class StaticMeshDataProvider: MeshDataProvider {
    public var grid: MeshGradientGrid<ControlPoint>
	
    public init(grid: MeshGradientGrid<ControlPoint>) {
		self.grid = grid
	}
}
