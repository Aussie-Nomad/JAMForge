//
//  PayloadLibraryView.swift
//  JAMForge Profile Builder
//
//  Created by JAMForge on $(date +%m/%d/%y).
//

import SwiftUI

struct PayloadLibraryView: View {
    @ObservedObject var viewModel: ProfileBuilderViewModel
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var showTemplates = false
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            searchAndFiltersView
            payloadListView
            templatesView
        }
        .background(Color.orange)
        .padding()
    }
    
    private var headerView: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.black)
            .frame(height: 40)
            .overlay(
                Text("PAYLOAD LIBRARY")
                    .font(.headline)
                    .fontWeight(.black)
                    .foregroundColor(.yellow)
            )
    }
    
    private var searchAndFiltersView: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search payloads...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding(8)
            .background(Color.yellow)
            .cornerRadius(8)
            
            // Category Filter
            Picker("Category", selection: $selectedCategory) {
                ForEach(viewModel.categories, id: \.self) { category in
                    Text(category).tag(category)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding(8)
            .background(Color.yellow)
            .cornerRadius(8)
        }
    }
    
    private var payloadListView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(filteredPayloads) { payload in
                    PayloadLibraryItemView(payload: payload)
                        .onDrag {
                            viewModel.draggedPayload = payload
                            return NSItemProvider(object: payload.id as NSString)
                        }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private var templatesView: some View {
        VStack(spacing: 8) {
            Button(action: { showTemplates.toggle() }) {
                HStack {
                    Image(systemName: "plus")
                    Text("TEMPLATES")
                        .fontWeight(.black)
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color.black)
                .foregroundColor(.yellow)
                .cornerRadius(8)
            }
            
            if showTemplates {
                ForEach(viewModel.templates, id: \.name) { template in
                    TemplateRowView(template: template, viewModel: viewModel)
                }
            }
        }
    }
    
    private var filteredPayloads: [Payload] {
        viewModel.allPayloads.filter { payload in
            let matchesCategory = selectedCategory == "All" || payload.category == selectedCategory
            let matchesSearch = searchText.isEmpty || 
                               payload.name.localizedCaseInsensitiveContains(searchText) ||
                               payload.description.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }
}

struct PayloadLibraryItemView: View {
    let payload: Payload
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(payload.icon)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(payload.name)
                        .font(.caption)
                        .fontWeight(.black)
                        .lineLimit(1)
                    
                    Text(payload.description)
                        .font(.caption2)
                        .opacity(0.7)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            
            HStack(spacing: 4) {
                ForEach(payload.platforms, id: \.self) { platform in
                    HStack(spacing: 2) {
                        platformIcon(for: platform)
                        Text(platform)
                            .font(.caption2)
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(3)
                }
                Spacer()
            }
        }
        .padding(12)
        .background(Color.yellow)
        .foregroundColor(.black)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    @ViewBuilder
    private func platformIcon(for platform: String) -> some View {
        switch platform {
        case "iOS":
            Image(systemName: "iphone")
                .foregroundColor(.blue)
                .font(.caption2)
        case "macOS":
            Image(systemName: "laptopcomputer")
                .foregroundColor(.gray)
                .font(.caption2)
        case "tvOS":
            Image(systemName: "appletv")
                .foregroundColor(.purple)
                .font(.caption2)
        default:
            Image(systemName: "questionmark")
                .foregroundColor(.gray)
                .font(.caption2)
        }
    }
}

struct TemplateRowView: View {
    let template: ProfileTemplate
    let viewModel: ProfileBuilderViewModel
    
    var body: some View {
        Button(action: { viewModel.applyTemplate(template) }) {
            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
                
                Text(template.description)
                    .font(.caption2)
                    .foregroundColor(.yellow.opacity(0.7))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.gray.opacity(0.8))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PayloadLibraryView(viewModel: ProfileBuilderViewModel())
        .frame(width: 320, height: 600)
}