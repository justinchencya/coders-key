//
//  ContentView.swift
//  CodersKey
//
//  Created by Justin Chen on 8/30/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(UIColor.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 24) {
                    // Header Section
                    VStack(spacing: 12) {
                        Image("app_logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        
                        VStack(spacing: 6) {
                            Text("CodersKey")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text("© 2025 nerdyStuff")
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 16)
                    
                    // Instructions Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("How to Use")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .padding(.bottom, 4)
                        
                        VStack(spacing: 16) {
                            InstructionStep(number: "1", text: "Go to Settings > General > Keyboard > Keyboards")
                            InstructionStep(number: "2", text: "Tap 'Add New Keyboard' and select 'CodersKey'")
                            InstructionStep(number: "3", text: "Tap on 'CodersKey' and enable 'Allow Full Access'")
                            InstructionStep(number: "4", text: "Switch to the keyboard by tapping the globe icon")
                            InstructionStep(number: "5", text: "Long press the last key on the third row (.) to select other keys (; or ,)")
                        }
                    }
                    .padding(20)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 5)
                    .padding(.horizontal)
                    
                    // Action Links
                    VStack(spacing: 16) {
                        MenuLink(title: "About Us", url: "https://www.nerdystuff.xyz")
                        MenuLink(title: "Contact", url: "https://www.nerdystuff.xyz/pages/contact-us")
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .frame(maxWidth: 500) // Constrain width for larger screens
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Supporting Views

struct InstructionStep: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(number)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color.blue)
                        .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
                )
            
            Text(text)
                .font(.system(size: 17, design: .rounded))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4) // Align text baseline with circle center visually
        }
    }
}

struct MenuLink: View {
    let title: String
    let url: String
    
    var body: some View {
        Link(destination: URL(string: url)!) {
            HStack {
                Text(title)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.primary)
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
}

#Preview {
    ContentView()
}
