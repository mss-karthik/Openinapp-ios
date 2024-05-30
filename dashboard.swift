import SwiftUI
import Combine
import Charts // Assuming we are using Charts library for the graph

struct DashboardResponse: Codable {
    let status: Bool
    let statusCode: Int
    let message: String
    let supportWhatsAppNumber: String
    let extraIncome: Double
    let totalLinks: Int
    let totalClicks: Int
    let todayClicks: Int
    let topSource: String
    let topLocation: String
    let startTime: String
    let linksCreatedToday: Int
    let appliedCampaign: Int
    let data: DashboardData
    
    enum CodingKeys: String, CodingKey {
        case status
        case statusCode = "statusCode"
        case message
        case supportWhatsAppNumber = "support_whatsapp_number"
        case extraIncome = "extra_income"
        case totalLinks = "total_links"
        case totalClicks = "total_clicks"
        case todayClicks = "today_clicks"
        case topSource = "top_source"
        case topLocation = "top_location"
        case startTime = "startTime"
        case linksCreatedToday = "links_created_today"
        case appliedCampaign = "applied_campaign"
        case data
    }
}

struct DashboardData: Codable {
    let recentLinks: [Link]
    let topLinks: [Link]
    let overallUrlChart: [String: Int]

    enum CodingKeys: String, CodingKey {
        case recentLinks = "recent_links"
        case topLinks = "top_links"
        case overallUrlChart = "overall_url_chart"
    }
}

struct Link: Codable, Identifiable {
    let id = UUID()
    let urlId: Int
    let webLink: String
    let smartLink: String
    let title: String
    let totalClicks: Int
    let originalImage: String?
    let thumbnail: String?
    let timesAgo: String
    let createdAt: String
    let domainId: String
    let urlPrefix: String?
    let urlSuffix: String
    let app: String
    let isFavourite: Bool

    enum CodingKeys: String, CodingKey {
        case urlId = "url_id"
        case webLink = "web_link"
        case smartLink = "smart_link"
        case title
        case totalClicks = "total_clicks"
        case originalImage = "original_image"
        case thumbnail
        case timesAgo = "times_ago"
        case createdAt = "created_at"
        case domainId = "domain_id"
        case urlPrefix = "url_prefix"
        case urlSuffix = "url_suffix"
        case app
        case isFavourite = "is_favourite"
    }
}

struct ChartData: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
}

class DashboardViewModel: ObservableObject {
    @Published var topLinks: [Link] = []
    @Published var recentLinks: [Link] = []
    @Published var chartData: [ChartData] = []

    private var cancellables = Set<AnyCancellable>()
    private let url = URL(string: "https://api.inopenapp.com/api/v1/dashboardNew")!
    private let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MjU5MjcsImlhdCI6MTY3NDU1MDQ1MH0.dCkW0ox8tbjJA2GgUx2UEwNlbTZ7Rr38PVFJevYcXFI"

    init() {
        fetchData()
    }

    func fetchData() {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTaskPublisher(for: request)
            .map { $0.data }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    print("Error fetching data: \(error)")
                case .finished:
                    break
                }
            }, receiveValue: { data in
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw JSON response: \(jsonString)")
                }
                do {
                    let response = try JSONDecoder().decode(DashboardResponse.self, from: data)
                    self.topLinks = response.data.topLinks
                    self.recentLinks = response.data.recentLinks
                    self.chartData = response.data.overallUrlChart.map { ChartData(label: $0.key, value: Double($0.value)) }
                } catch {
                    print("Decoding error: \(error)")
                }
            })
            .store(in: &cancellables)
    }
}

struct ContentView: View {
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationView {
            VStack {
                Text(greetingMessage())
                    .font(.largeTitle)
                    .padding()

                ChartView(data: viewModel.chartData)
                    .padding()

                TabView {
                    LinkListView(links: viewModel.topLinks, title: "Top Links")
                        .tabItem {
                            Label("Top Links", systemImage: "link")
                        }
                    LinkListView(links: viewModel.recentLinks, title: "Recent Links")
                        .tabItem {
                            Label("Recent Links", systemImage: "clock")
                        }
                }
            }
            .navigationTitle("Dashboard")
        }
    }

    func greetingMessage() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "HELLO KARTHIK"
        case 12..<17: return "Good Afternoon KARTHIK"
        case 17..<22: return "Good Evening KARTHIK"
        default: return "Good Night KARTHIK"
        }
    }
}

struct LinkListView: View {
    let links: [Link]
    let title: String

    var body: some View {
        List(links) { link in
            LinkRow(link: link)
        }
        .navigationTitle(title)
    }
}

struct LinkRow: View {
    let link: Link

    var body: some View {
        VStack(alignment: .leading) {
            Text(link.title)
                .font(.headline)
            Text(link.webLink)
                .font(.subheadline)
                .foregroundColor(.blue)
        }
    }
}

struct ChartView: View {
    let data: [ChartData]

    var body: some View {
        Chart(data) { item in
            BarMark(
                x: .value("Label", item.label),
                y: .value("Value", item.value)
            )
        }
        .frame(height: 200)
    }
}

@main
struct DashboardApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
