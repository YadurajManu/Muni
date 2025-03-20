import SwiftUI

struct CurrencyLanguageView: View {
    @EnvironmentObject private var userManager: UserManager
    @Environment(\.locale) private var locale
    @AppStorage("selectedLanguage") private var selectedLanguage = "en"
    
    private let currencies = [
        Currency(symbol: "₹", name: "Indian Rupee", code: "INR"),
        Currency(symbol: "$", name: "US Dollar", code: "USD"),
        Currency(symbol: "€", name: "Euro", code: "EUR"),
        Currency(symbol: "£", name: "British Pound", code: "GBP"),
        Currency(symbol: "¥", name: "Japanese Yen", code: "JPY")
    ]
    
    private let languages = [
        Language(code: "en", name: "English"),
        Language(code: "hi", name: "Hindi"),
        Language(code: "bn", name: "Bengali"),
        Language(code: "te", name: "Telugu"),
        Language(code: "mr", name: "Marathi")
    ]
    
    var body: some View {
        List {
            Section(header: Text("Currency")) {
                ForEach(currencies) { currency in
                    Button(action: {
                        userManager.currency = currency.symbol
                    }) {
                        HStack {
                            Text(currency.symbol)
                                .font(.title2)
                                .foregroundColor(Theme.primary)
                                .frame(width: 40)
                            
                            VStack(alignment: .leading) {
                                Text(currency.name)
                                    .foregroundColor(Theme.text)
                                Text(currency.code)
                                    .font(.caption)
                                    .foregroundColor(Theme.text.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            if userManager.currency == currency.symbol {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Theme.primary)
                            }
                        }
                    }
                }
            }
            
            Section(header: Text("Language")) {
                ForEach(languages) { language in
                    Button(action: {
                        selectedLanguage = language.code
                        // In a real app, you would handle language change here
                    }) {
                        HStack {
                            Text(language.name)
                                .foregroundColor(Theme.text)
                            
                            Spacer()
                            
                            if selectedLanguage == language.code {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Theme.primary)
                            }
                        }
                    }
                }
            }
            
            Section(header: Text("Format")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Number Format")
                        .font(.subheadline)
                        .foregroundColor(Theme.text.opacity(0.7))
                    
                    Text("1,234.56")
                        .font(.title3)
                        .foregroundColor(Theme.text)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date Format")
                        .font(.subheadline)
                        .foregroundColor(Theme.text.opacity(0.7))
                    
                    Text(Date(), style: .date)
                        .font(.title3)
                        .foregroundColor(Theme.text)
                }
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Currency & Language")
    }
}

struct Currency: Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
    let code: String
}

struct Language: Identifiable {
    let id = UUID()
    let code: String
    let name: String
} 