import SwiftUI
import MapKit
import CoreLocation

struct BranchMapView: View {
    @StateObject private var viewModel = BranchMapViewModel()
    @State private var showNearestBranchSheet: Bool = false
    @State private var showPermissionAlert: Bool = false
    @State private var selectedMapBranch: Branch? = nil
    @State private var showBranchDetail: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Map
                Map(coordinateRegion: $viewModel.region,
                    interactionModes: .all,
                    showsUserLocation: true,
                    annotationItems: viewModel.branches) { branch in
                    MapAnnotation(coordinate: branch.coordinate) {
                        BranchAnnotationView(branch: branch) {
                            selectedMapBranch = branch
                            showBranchDetail = true
                        }
                    }
                }
                .ignoresSafeArea(edges: .bottom)
                .overlay(
                    // Overlay controls
                    mapControlsOverlay
                    , alignment: .bottomTrailing
                )
                
                // Loading overlay
                if viewModel.isLoading && viewModel.branches.isEmpty {
                    loadingOverlay
                }
            }
            .navigationTitle("Отделения")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showNearestBranchSheet = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "location.magnifyingglass")
                            Text("Ближайшее")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.loadBranches()
                        viewModel.requestLocationPermission()
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            viewModel.loadBranches()
            viewModel.requestLocationPermission()
        }
        .sheet(isPresented: $showNearestBranchSheet) {
            NearestBranchSheet(viewModel: viewModel)
        }
        .alert("Доступ к геолокации", isPresented: $showPermissionAlert) {
            Button("Отмена", role: .cancel) {}
            Button("Настройки") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("Для поиска ближайшего отделения необходим доступ к геолокации")
        }
        .onChange(of: viewModel.locationPermissionDenied) { denied in
            if denied {
                showPermissionAlert = true
            }
        }
        .sheet(isPresented: $showBranchDetail) {
            if let branch = selectedMapBranch {
                BranchDetailSheet(branch: branch, userLocation: viewModel.userLocation)
            }
        }
    }
    
    // MARK: - Overlays
    
    private var mapControlsOverlay: some View {
        VStack(spacing: 12) {
            // Center on user
            Button(action: {
                viewModel.centerOnUser()
            }) {
                Image(systemName: "location.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.blue)
                    .frame(width: 48, height: 48)
                    .background(Color(.systemBackground))
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            }
            
            // Center on nearest branch
            Button(action: {
                viewModel.centerOnNearestBranch()
            }) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.purple)
                    .frame(width: 48, height: 48)
                    .background(Color(.systemBackground))
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            }
        }
        .padding(.trailing, 16)
        .padding(.bottom, 32)
    }
    
    private var loadingOverlay: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.2)
                
                Text("Загрузка отделений...")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 4)
            
            Spacer()
        }
    }
}

// MARK: - Branch Annotation View

struct BranchAnnotationView: View {
    let branch: Branch
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(Color.purple)
                        .frame(width: 36, height: 36)
                        .shadow(color: .purple.opacity(0.3), radius: 6, x: 0, y: 3)
                    
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
                
                Triangle()
                    .fill(Color.purple)
                    .frame(width: 12, height: 8)
                    .offset(y: -2)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Nearest Branch Sheet

struct NearestBranchSheet: View {
    @ObservedObject var viewModel: BranchMapViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.userLocation == nil {
                        locationRequiredView
                    } else if let nearest = viewModel.nearestBranch {
                        nearestBranchCard(branch: nearest)
                        
                        // All branches sorted by distance
                        branchesByDistanceList
                    } else {
                        noBranchesView
                    }
                }
                .padding(20)
            }
            .navigationTitle("Ближайшее отделение")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private var locationRequiredView: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.slash.fill")
                .font(.system(size: 56))
                .foregroundColor(.secondary.opacity(0.6))
            
            Text("Местоположение не определено")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.secondary)
            
            Button(action: {
                viewModel.requestLocationPermission()
            }) {
                Text("Определить местоположение")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
        .padding(.top, 60)
    }
    
    private func nearestBranchCard(branch: Branch) -> some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                
                Text("Ближайшее отделение")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            // Branch info
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.purple)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(branch.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                        
                        if let userLoc = viewModel.userLocation {
                            Text(branch.formattedDistance(from: userLoc))
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.green)
                        }
                    }
                    
                    Spacer()
                }
                
                Divider()
                
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "mappin")
                        .foregroundColor(.red)
                        .frame(width: 20)
                    
                    Text(branch.address)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                
                // Coordinates
                HStack(spacing: 12) {
                    Label(
                        String(format: "%.4f", branch.latitude),
                        systemImage: "arrow.up.arrow.down"
                    )
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    
                    Label(
                        String(format: "%.4f", branch.longitude),
                        systemImage: "arrow.left.arrow.right"
                    )
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(14)
            
            // Actions
            HStack(spacing: 12) {
                Button(action: {
                    viewModel.centerOnNearestBranch()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "map.fill")
                        Text("Показать на карте")
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.purple)
                    .cornerRadius(12)
                }
                
                Button(action: {
                    viewModel.navigateToBranch(branch)
                }) {
                    HStack {
                        Image(systemName: "location.fill")
                        Text("Маршрут")
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.purple)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
    
    private var branchesByDistanceList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Все отделения по расстоянию")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            let sortedBranches = viewModel.branches.sorted {
                guard let userLoc = viewModel.userLocation else { return false }
                return $0.distance(from: userLoc) < $1.distance(from: userLoc)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(sortedBranches) { branch in
                    BranchDistanceRow(
                        branch: branch,
                        userLocation: viewModel.userLocation,
                        isNearest: branch.id == viewModel.nearestBranch?.id
                    )
                }
            }
        }
        .padding(.top, 8)
    }
    
    private var noBranchesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "building.columns")
                .font(.system(size: 56))
                .foregroundColor(.secondary.opacity(0.6))
            
            Text("Отделения не найдены")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(.top, 60)
    }
}

// MARK: - Branch Distance Row

struct BranchDistanceRow: View {
    let branch: Branch
    let userLocation: CLLocation?
    let isNearest: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isNearest ? Color.yellow.opacity(0.2) : Color.purple.opacity(0.15))
                    .frame(width: 42, height: 42)
                
                Image(systemName: isNearest ? "star.fill" : "building.columns.fill")
                    .font(.system(size: 18))
                    .foregroundColor(isNearest ? .yellow : .purple)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(branch.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(branch.address)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if let userLoc = userLocation {
                Text(branch.formattedDistance(from: userLoc))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isNearest ? .green : .secondary)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isNearest ? Color.yellow.opacity(0.5) : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Branch Detail Sheet

struct BranchDetailSheet: View {
    let branch: Branch
    let userLocation: CLLocation?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 140)
                        
                        VStack(spacing: 8) {
                            Image(systemName: "building.columns.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                            
                            Text(branch.name)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Info
                    VStack(spacing: 16) {
                        infoRow(icon: "mappin", title: "Адрес", value: branch.address, color: .red)
                        infoRow(icon: "arrow.up.arrow.down", title: "Широта", value: String(format: "%.6f", branch.latitude), color: .blue)
                        infoRow(icon: "arrow.left.arrow.right", title: "Долгота", value: String(format: "%.6f", branch.longitude), color: .blue)
                        
                        if let userLoc = userLocation {
                            infoRow(icon: "location.fill", title: "Расстояние", value: branch.formattedDistance(from: userLoc), color: .green)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(16)
            }
            .navigationTitle("Отделение")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func infoRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.15))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Preview

struct BranchMapView_Previews: PreviewProvider {
    static var previews: some View {
        BranchMapView()
    }
}
