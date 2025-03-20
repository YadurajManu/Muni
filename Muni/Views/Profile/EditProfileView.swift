import SwiftUI

struct EditProfileView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var userManager: UserManager
    
    @State private var name: String = ""
    @State private var monthlyIncome: String = ""
    @State private var monthlyBudget: String = ""
    @State private var selectedGoal: String = ""
    @State private var showSaveConfirmation = false
    
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            Form {
                // Personal information section
                Section(header: Text("Personal Information")) {
                    TextField("Your Name", text: $name)
                        .font(.body)
                        .padding(.vertical, 8)
                }
                
                // Financial information section
                Section(header: Text("Financial Information")) {
                    HStack {
                        Text(userManager.currency)
                            .foregroundColor(Theme.text.opacity(0.7))
                        TextField("Monthly Income", text: $monthlyIncome)
                            .keyboardType(.decimalPad)
                    }
                    .padding(.vertical, 8)
                    
                    HStack {
                        Text(userManager.currency)
                            .foregroundColor(Theme.text.opacity(0.7))
                        TextField("Monthly Budget", text: $monthlyBudget)
                            .keyboardType(.decimalPad)
                    }
                    .padding(.vertical, 8)
                }
                
                // Financial goals section
                Section(header: Text("Financial Goal")) {
                    Picker("Goal", selection: $selectedGoal) {
                        Text("None").tag("")
                        ForEach(UserManager.financialGoalOptions(), id: \.self) { goal in
                            Text(goal).tag(goal)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.vertical, 8)
                }
                
                // Information about saving
                Section(footer: Text("Your profile information helps us provide personalized financial insights.")) {
                    Button(action: saveProfile) {
                        HStack {
                            Spacer()
                            Text("Save Changes")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .background(Theme.primary)
                        .cornerRadius(10)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .onAppear(perform: loadUserData)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .alert(isPresented: $showSaveConfirmation) {
                Alert(
                    title: Text("Profile Updated"),
                    message: Text("Your profile information has been saved."),
                    dismissButton: .default(Text("OK")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }
    
    private func loadUserData() {
        name = userManager.name
        monthlyIncome = userManager.monthlyIncome > 0 ? String(format: "%.2f", userManager.monthlyIncome) : ""
        monthlyBudget = userManager.monthlyBudget > 0 ? String(format: "%.2f", userManager.monthlyBudget) : ""
        selectedGoal = userManager.financialGoal
    }
    
    private func saveProfile() {
        // Save user name
        userManager.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Save monthly income
        if let income = Double(monthlyIncome.replacingOccurrences(of: ",", with: "")) {
            userManager.monthlyIncome = income
        }
        
        // Save monthly budget
        if let budget = Double(monthlyBudget.replacingOccurrences(of: ",", with: "")) {
            userManager.monthlyBudget = budget
        }
        
        // Save financial goal
        userManager.financialGoal = selectedGoal
        
        // Save all user data
        userManager.saveUserData()
        
        // Show confirmation
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        showSaveConfirmation = true
    }
}

struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        EditProfileView()
            .environmentObject(UserManager())
    }
} 