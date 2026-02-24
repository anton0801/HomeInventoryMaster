import SwiftUI
import WebKit

struct MaintenanceView: View {
    @StateObject private var coreDataManager = CoreDataManager.shared
    @State private var selectedDate = Date()
    @State private var showCalendar = true
    
    var allTasks: [(item: Item, task: MaintenanceTask)] {
        var tasks: [(Item, MaintenanceTask)] = []
        for item in coreDataManager.items {
            for task in item.maintenanceTasks {
                tasks.append((item, task))
            }
        }
        return tasks.sorted { pair1, pair2 in
            let date1 = pair1.1.nextDueDate ?? Date.distantFuture
            let date2 = pair2.1.nextDueDate ?? Date.distantFuture
            return date1 < date2
        }
    }
    
    var upcomingTasks: [(item: Item, task: MaintenanceTask)] {
        allTasks.filter { 
            guard let dueDate = $0.task.nextDueDate else { return false }
            return dueDate >= Date() && dueDate <= Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        }
    }
    
    var overdueTasks: [(item: Item, task: MaintenanceTask)] {
        allTasks.filter { $0.task.isOverdue }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Summary cards
                        summarySection
                        
                        // Overdue tasks
                        if !overdueTasks.isEmpty {
                            overdueSection
                        }
                        
                        // Upcoming tasks
                        upcomingSection
                        
                        // Calendar view toggle
                        calendarToggleSection
                        
                        if showCalendar {
                            calendarSection
                        }
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Maintenance")
        }
    }
    
    private var summarySection: some View {
        HStack(spacing: Theme.Spacing.md) {
            MaintenanceSummaryCard(
                title: "Overdue",
                count: overdueTasks.count,
                icon: "exclamationmark.triangle.fill",
                color: Theme.Colors.error
            )
            
            MaintenanceSummaryCard(
                title: "Upcoming",
                count: upcomingTasks.count,
                icon: "calendar.badge.clock",
                color: Theme.Colors.warning
            )
        }
    }
    
    private var overdueSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(Theme.Colors.error)
                Text("Overdue Tasks")
                    .font(Theme.Fonts.headline())
                    .foregroundColor(Theme.Colors.textPrimary)
            }
            
            ForEach(overdueTasks, id: \.task.id) { item, task in
                NavigationLink(destination: MaintenanceTaskDetailView(item: item, task: task)) {
                    MaintenanceTaskCard(item: item, task: task, isOverdue: true)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(Theme.Colors.accent)
                Text("Next 30 Days")
                    .font(Theme.Fonts.headline())
                    .foregroundColor(Theme.Colors.textPrimary)
            }
            
            if upcomingTasks.isEmpty {
                Text("No upcoming maintenance tasks")
                    .font(Theme.Fonts.body())
                    .foregroundColor(Theme.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .cardStyle()
            } else {
                ForEach(upcomingTasks, id: \.task.id) { item, task in
                    NavigationLink(destination: MaintenanceTaskDetailView(item: item, task: task)) {
                        MaintenanceTaskCard(item: item, task: task, isOverdue: false)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var calendarToggleSection: some View {
        Button(action: {
            withAnimation {
                showCalendar.toggle()
            }
        }) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(Theme.Colors.accent)
                Text(showCalendar ? "Hide Calendar" : "Show Calendar")
                    .font(Theme.Fonts.body())
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Spacer()
                
                Image(systemName: showCalendar ? "chevron.up" : "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            .padding()
            .cardStyle()
        }
    }
    
    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            DatePicker(
                "Select Date",
                selection: $selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(GraphicalDatePickerStyle())
            .padding()
            .cardStyle()
            
            // Tasks for selected date
            let tasksForDate = tasksFor(date: selectedDate)
            
            if !tasksForDate.isEmpty {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Tasks on \(selectedDate.toString())")
                        .font(Theme.Fonts.headline(size: 16))
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    ForEach(tasksForDate, id: \.task.id) { item, task in
                        MaintenanceTaskCard(item: item, task: task, isOverdue: task.isOverdue)
                    }
                }
            }
        }
    }
    
    private func tasksFor(date: Date) -> [(item: Item, task: MaintenanceTask)] {
        allTasks.filter { _, task in
            guard let dueDate = task.nextDueDate else { return false }
            return Calendar.current.isDate(dueDate, inSameDayAs: date)
        }
    }
}

struct MaintenanceSummaryCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.textPrimary)
            
            Text(title)
                .font(Theme.Fonts.caption())
                .foregroundColor(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .cardStyle()
    }
}

struct MaintenanceTaskCard: View {
    let item: Item
    let task: MaintenanceTask
    let isOverdue: Bool
    
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Status indicator
            VStack(spacing: 4) {
                Image(systemName: isOverdue ? "exclamationmark.circle.fill" : "clock.fill")
                    .font(.system(size: 22))
                    .foregroundColor(isOverdue ? Theme.Colors.error : Theme.Colors.accent)
                
                if let daysUntil = task.daysUntilDue {
                    Text("\(abs(daysUntil))d")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(isOverdue ? Theme.Colors.error : Theme.Colors.textSecondary)
                }
            }
            .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(task.name)
                    .font(Theme.Fonts.headline(size: 17))
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Text(item.name)
                    .font(Theme.Fonts.body(size: 14))
                    .foregroundColor(Theme.Colors.textSecondary)
                
                if let nextDue = task.nextDueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                        Text(nextDue.toString())
                            .font(Theme.Fonts.caption(size: 12))
                    }
                    .foregroundColor(isOverdue ? Theme.Colors.error : Theme.Colors.accent)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.Colors.textSecondary)
        }
        .padding()
        .cardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(isOverdue ? Theme.Colors.error : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Maintenance Task Detail View
struct MaintenanceTaskDetailView: View {
    let item: Item
    @State var task: MaintenanceTask
    @StateObject private var coreDataManager = CoreDataManager.shared
    @State private var showCompletionSheet = false
    @State private var completionNotes = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Status card
                    statusCard
                    
                    // Item info
                    itemInfoCard
                    
                    // Task details
                    taskDetailsCard
                    
                    // History
                    historyCard
                    
                    // Actions
                    actionButtons
                }
                .padding()
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Maintenance Task")
        .sheet(isPresented: $showCompletionSheet) {
            CompleteTaskView(task: $task, notes: $completionNotes) {
                completeTask()
            }
        }
    }
    
    private var statusCard: some View {
        VStack(spacing: Theme.Spacing.md) {
            if task.isOverdue {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Theme.Colors.error)
                    
                    Text("Overdue")
                        .font(Theme.Fonts.headline(size: 20))
                        .foregroundColor(Theme.Colors.error)
                    
                    Spacer()
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next Due Date")
                        .font(Theme.Fonts.caption())
                        .foregroundColor(Theme.Colors.textSecondary)
                    
                    if let nextDue = task.nextDueDate {
                        Text(nextDue.toString())
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.Colors.textPrimary)
                        
                        if let days = task.daysUntilDue {
                            Text(days >= 0 ? "In \(days) days" : "\(abs(days)) days ago")
                                .font(Theme.Fonts.caption())
                                .foregroundColor(task.isOverdue ? Theme.Colors.error : Theme.Colors.accent)
                        }
                    } else {
                        Text("Not scheduled")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .cardStyle()
    }
    
    private var itemInfoCard: some View {
        NavigationLink(destination: ItemDetailView(item: item)) {
            HStack(spacing: Theme.Spacing.md) {
                if let firstImage = item.images.first,
                   let uiImage = UIImage(data: firstImage.imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                            .fill(Theme.Colors.accent.opacity(0.1))
                        
                        Image(systemName: "photo")
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    .frame(width: 60, height: 60)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("For Item")
                        .font(Theme.Fonts.caption())
                        .foregroundColor(Theme.Colors.textSecondary)
                    
                    Text(item.name)
                        .font(Theme.Fonts.headline(size: 17))
                        .foregroundColor(Theme.Colors.textPrimary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            .padding()
            .cardStyle()
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var taskDetailsCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Task Details")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textPrimary)
            
            DetailRow(
                icon: "wrench.and.screwdriver",
                title: "Task",
                value: task.name,
                color: Theme.Colors.accent
            )
            
            DetailRow(
                icon: "arrow.clockwise",
                title: "Frequency",
                value: "Every \(task.intervalDays) days",
                color: Theme.Colors.gold
            )
            
            if let lastCompleted = task.lastCompletedDate {
                DetailRow(
                    icon: "checkmark.circle.fill",
                    title: "Last Completed",
                    value: lastCompleted.toString(),
                    color: Theme.Colors.success
                )
            }
            
            if let notes = task.notes {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "note.text")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.Colors.warning)
                            .frame(width: 24)
                        
                        Text("Notes")
                            .font(Theme.Fonts.body(size: 14))
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    
                    Text(notes)
                        .font(Theme.Fonts.body())
                        .foregroundColor(Theme.Colors.textPrimary)
                        .padding(.leading, 32)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.Colors.background)
                .cornerRadius(Theme.CornerRadius.sm)
            }
        }
        .padding()
        .cardStyle()
    }
    
    private var historyCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Completion History")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textPrimary)
            
            if let lastCompleted = task.lastCompletedDate {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Theme.Colors.success)
                    
                    Text("Completed on \(lastCompleted.toString())")
                        .font(Theme.Fonts.body())
                        .foregroundColor(Theme.Colors.textPrimary)
                }
                .padding()
                .background(Theme.Colors.success.opacity(0.1))
                .cornerRadius(Theme.CornerRadius.sm)
            } else {
                Text("No completion history")
                    .font(Theme.Fonts.body())
                    .foregroundColor(Theme.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.Colors.background)
                    .cornerRadius(Theme.CornerRadius.sm)
            }
        }
        .padding()
        .cardStyle()
    }
    
    private var actionButtons: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Button(action: { showCompletionSheet = true }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Mark as Completed")
                }
            }
            .primaryButtonStyle()
            
            Button(action: {}) {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                    Text("Reschedule")
                }
            }
            .secondaryButtonStyle()
        }
    }
    
    private func completeTask() {
        task.markCompleted()
        
        // Update in Core Data
        var updatedItem = item
        if let index = updatedItem.maintenanceTasks.firstIndex(where: { $0.id == task.id }) {
            updatedItem.maintenanceTasks[index] = task
        }
        coreDataManager.updateItem(updatedItem)
        
        // Schedule notification
        NotificationManager.shared.scheduleMaintenanceNotification(for: task, itemName: item.name)
        
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Complete Task View
struct CompleteTaskView: View {
    @Binding var task: MaintenanceTask
    @Binding var notes: String
    let onComplete: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                
                VStack(spacing: Theme.Spacing.lg) {
                    // Success icon
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.success.opacity(0.1))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Theme.Colors.success)
                    }
                    .padding(.top, 40)
                    
                    Text("Mark as Completed")
                        .font(Theme.Fonts.title(size: 24))
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    Text(task.name)
                        .font(Theme.Fonts.body())
                        .foregroundColor(Theme.Colors.textSecondary)
                    
                    // Notes
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Completion Notes (Optional)")
                            .font(Theme.Fonts.caption())
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        TextEditor(text: $notes)
                            .frame(height: 120)
                            .padding(12)
                            .background(Theme.Colors.background)
                            .cornerRadius(Theme.CornerRadius.sm)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                    .stroke(Theme.Colors.textSecondary.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    Button(action: {
                        onComplete()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Complete Task")
                    }
                    .primaryButtonStyle()
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Add Maintenance Task View
struct AddMaintenanceTaskView: View {
    let item: Item
    @StateObject private var coreDataManager = CoreDataManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    @State private var taskName = ""
    @State private var intervalDays = 30
    @State private var notes = ""
    
    let intervalOptions = [7, 14, 30, 60, 90, 180, 365]
    
    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    FloatingTextField(title: "Task Name *", text: $taskName)
                        .cardStyle()
                    
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Frequency")
                            .font(Theme.Fonts.caption())
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        Picker("Frequency", selection: $intervalDays) {
                            ForEach(intervalOptions, id: \.self) { days in
                                Text(frequencyText(for: days)).tag(days)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                        .background(Theme.Colors.background)
                        .cornerRadius(Theme.CornerRadius.sm)
                    }
                    .cardStyle()
                    
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Notes (Optional)")
                            .font(Theme.Fonts.caption())
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        TextEditor(text: $notes)
                            .frame(height: 120)
                            .padding(12)
                            .background(Theme.Colors.background)
                            .cornerRadius(Theme.CornerRadius.sm)
                    }
                    .cardStyle()
                    
                    Spacer()
                    
                    Button(action: saveTask) {
                        Text("Add Task")
                    }
                    .primaryButtonStyle()
                    .disabled(taskName.isEmpty)
                    .opacity(taskName.isEmpty ? 0.6 : 1.0)
                }
                .padding()
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Add Maintenance Task")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func frequencyText(for days: Int) -> String {
        if days < 30 {
            return "Every \(days) days"
        } else if days == 30 {
            return "Monthly"
        } else if days == 90 {
            return "Quarterly"
        } else if days == 180 {
            return "Bi-annually"
        } else if days == 365 {
            return "Annually"
        } else {
            return "Every \(days) days"
        }
    }
    
    private func saveTask() {
        let task = MaintenanceTask(
            name: taskName,
            intervalDays: intervalDays,
            notes: notes.isEmpty ? nil : notes
        )
        
        var updatedItem = item
        updatedItem.maintenanceTasks.append(task)
        coreDataManager.updateItem(updatedItem)
        
        // Schedule notification
        NotificationManager.shared.scheduleMaintenanceNotification(for: task, itemName: item.name)
        
        presentationMode.wrappedValue.dismiss()
    }
}

struct StatsWebView: View {
    @State private var url: String? = ""
    @State private var loaded = false
    
    var body: some View {
        ZStack {
            if loaded, let urlStr = url, let destination = URL(string: urlStr) {
                WebInterface(url: destination).ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { initialize() }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LoadTempURL"))) { _ in update() }
    }
    
    private func initialize() {
        let temp = UserDefaults.standard.string(forKey: "temp_url")
        let saved = UserDefaults.standard.string(forKey: "sm_endpoint_primary") ?? ""
        url = temp ?? saved
        loaded = true
        if temp != nil { UserDefaults.standard.removeObject(forKey: "temp_url") }
    }
    
    private func update() {
        if let temp = UserDefaults.standard.string(forKey: "temp_url"), !temp.isEmpty {
            loaded = false
            url = temp
            UserDefaults.standard.removeObject(forKey: "temp_url")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { loaded = true }
        }
    }
}

struct WebInterface: UIViewRepresentable {
    let url: URL
    
    func makeCoordinator() -> WebManager { WebManager() }
    
    func makeUIView(context: Context) -> WKWebView {
        let web = constructWeb(manager: context.coordinator)
        context.coordinator.web = web
        context.coordinator.load(url, in: web)
        Task { await context.coordinator.restoreCookies(in: web) }
        return web
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    private func constructWeb(manager: WebManager) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.processPool = WKProcessPool()
        
        let prefs = WKPreferences()
        prefs.javaScriptEnabled = true
        prefs.javaScriptCanOpenWindowsAutomatically = true
        config.preferences = prefs
        
        let controller = WKUserContentController()
        let script = WKUserScript(
            source: """
            (function() {
                const meta = document.createElement('meta');
                meta.name = 'viewport';
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                document.head.appendChild(meta);
                const style = document.createElement('style');
                style.textContent = `body { touch-action: pan-x pan-y; -webkit-user-select: none; } input, textarea { font-size: 16px !important; }`;
                document.head.appendChild(style);
                document.addEventListener('gesturestart', e => e.preventDefault());
                document.addEventListener('gesturechange', e => e.preventDefault());
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        controller.addUserScript(script)
        config.userContentController = controller
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        let pagePrefs = WKWebpagePreferences()
        pagePrefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = pagePrefs
        
        let web = WKWebView(frame: .zero, configuration: config)
        web.scrollView.minimumZoomScale = 1.0
        web.scrollView.maximumZoomScale = 1.0
        web.scrollView.bounces = false
        web.scrollView.bouncesZoom = false
        web.allowsBackForwardNavigationGestures = true
        web.scrollView.contentInsetAdjustmentBehavior = .never
        web.navigationDelegate = manager
        web.uiDelegate = manager
        return web
    }
}

final class WebManager: NSObject {
    weak var web: WKWebView?
    
    private var steps = 0
    private var stepLimit = 70
    private var last: URL?
    private var route: [URL] = []
    private var stable: URL?
    private var tabs: [WKWebView] = []
    private let jar = "stats_cookies"
    
    func load(_ url: URL, in web: WKWebView) {
        print("📊 [Stats] Load: \(url.absoluteString)")
        route = [url]
        steps = 0
        var req = URLRequest(url: url)
        req.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        web.load(req)
    }
    
    func restoreCookies(in web: WKWebView) {
        guard let data = UserDefaults.standard.object(forKey: jar) as? [String: [String: [HTTPCookiePropertyKey: AnyObject]]] else { return }
        let store = web.configuration.websiteDataStore.httpCookieStore
        let cookies = data.values.flatMap { $0.values }.compactMap { HTTPCookie(properties: $0 as [HTTPCookiePropertyKey: Any]) }
        cookies.forEach { store.setCookie($0) }
    }
    
    func persistCookies(from web: WKWebView) {
        let store = web.configuration.websiteDataStore.httpCookieStore
        store.getAllCookies { [weak self] cookies in
            guard let self = self else { return }
            var data: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            for cookie in cookies {
                var domain = data[cookie.domain] ?? [:]
                if let props = cookie.properties { domain[cookie.name] = props }
                data[cookie.domain] = domain
            }
            UserDefaults.standard.set(data, forKey: self.jar)
        }
    }
}

extension WebManager: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        last = url
        if canNavigate(url) {
            decisionHandler(.allow)
        } else {
            UIApplication.shared.open(url, options: [:])
            decisionHandler(.cancel)
        }
    }
    
    private func canNavigate(_ url: URL) -> Bool {
        let scheme = (url.scheme ?? "").lowercased()
        let path = url.absoluteString.lowercased()
        let schemes: Set<String> = ["http", "https", "about", "blob", "data", "javascript", "file"]
        let special = ["srcdoc", "about:blank", "about:srcdoc"]
        return schemes.contains(scheme) || special.contains { path.hasPrefix($0) } || path == "about:blank"
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        steps += 1
        if steps > stepLimit {
            webView.stopLoading()
            if let recovery = last { webView.load(URLRequest(url: recovery)) }
            steps = 0
            return
        }
        last = webView.url
        persistCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if let current = webView.url {
            stable = current
            print("✅ [Stats] Commit: \(current.absoluteString)")
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let current = webView.url { stable = current }
        steps = 0
        persistCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let code = (error as NSError).code
        if code == NSURLErrorHTTPTooManyRedirects, let recovery = last {
            webView.load(URLRequest(url: recovery))
        }
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust, let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

extension WebManager: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }
        let tab = WKWebView(frame: webView.bounds, configuration: configuration)
        tab.navigationDelegate = self
        tab.uiDelegate = self
        tab.allowsBackForwardNavigationGestures = true
        webView.addSubview(tab)
        tab.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tab.topAnchor.constraint(equalTo: webView.topAnchor),
            tab.bottomAnchor.constraint(equalTo: webView.bottomAnchor),
            tab.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
            tab.trailingAnchor.constraint(equalTo: webView.trailingAnchor)
        ])
        let gesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(closeTab(_:)))
        gesture.edges = .left
        tab.addGestureRecognizer(gesture)
        tabs.append(tab)
        if let url = navigationAction.request.url, url.absoluteString != "about:blank" {
            tab.load(navigationAction.request)
        }
        return tab
    }
    
    @objc private func closeTab(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        guard recognizer.state == .ended else { return }
        if let last = tabs.last {
            last.removeFromSuperview()
            tabs.removeLast()
        } else {
            web?.goBack()
        }
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}

