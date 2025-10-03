//
//  ContentView.swift
//  ios-bootcamp
//
//  Created by Jonah Chan on 10/3/25.
//
import SwiftUI
import Supabase

struct Todo: Codable, Identifiable {
    let id: Int
    var title: String
    var is_complete: Bool   // If your column is named `is_completed`, rename here AND in the insert/update payloads.
}

struct NewTodo: Encodable {
    let title: String
    let is_complete: Bool   // rename to is_completed if your column is named that
}


struct ContentView: View {
    @State private var todos: [Todo] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var newTitle = ""
    @State private var isAdding = false
    @FocusState private var addingFocused: Bool

    let client: SupabaseClient

    var body: some View {
        NavigationView {
            List {
                // Existing rows
                ForEach($todos) { $todo in
                    HStack {
                        Button {
                            Task { await toggle(todo) }
                        } label: {
                            Image(systemName: todo.is_complete ? "checkmark.circle.fill" : "circle")
                                .imageScale(.large)
                        }
                        .buttonStyle(.plain)

                        Text(todo.title)
                            .strikethrough(todo.is_complete, color: .secondary)
                            .foregroundStyle(todo.is_complete ? .secondary : .primary)
                        Spacer()
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(todo.is_complete ? "Uncheck" : "Done") {
                            Task { await toggle(todo) }
                        }
                    }
                }

                // New todo input — appears at the bottom
                Section {
                    HStack(spacing: 8) {
                        TextField("New todo", text: $newTitle)
                            .focused($addingFocused)
                            .submitLabel(.done)
                            .onSubmit { Task { await addTodo() } }

                        if isAdding { ProgressView().scaleEffect(0.8) }

                        Button("Add") { Task { await addTodo() } }
                            .disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isAdding)
                    }
                }
            }
            .navigationTitle("Todos")
            .task { await loadTodos() }
            .refreshable { await loadTodos() }
        }
    }

    private func loadTodos() async {
        isLoading = true; errorMessage = nil
        do {
            let rows: [Todo] = try await client
                .from("todos")
                .select()
                .order("id") // or .order("created_at") if you have that column
                .execute()
                .value
            await MainActor.run { todos = rows; isLoading = false }
        } catch {
            await MainActor.run { errorMessage = String(describing: error); isLoading = false }
            print("loadTodos error:", error)
        }
    }

    private func toggle(_ todo: Todo) async {
        guard let idx = todos.firstIndex(where: { $0.id == todo.id }) else { return }
        let newValue = !todos[idx].is_complete
        await MainActor.run { todos[idx].is_complete = newValue }  // optimistic

        do {
            let _: Todo = try await client
                .from("todos")
                .update(["is_complete": newValue])  // change key to "is_completed" if your DB uses that
                .eq("id", value: todo.id)
                .select()
                .single()
                .execute()
                .value
        } catch {
            await MainActor.run { todos[idx].is_complete.toggle() } // rollback
            print("toggle error:", error)
        }
    }

    private func addTodo() async {
        let title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, !isAdding else { return }
        isAdding = true

        // optimistic placeholder (negative id so it won't clash)
        let tempId = -Int(Date().timeIntervalSince1970)
        await MainActor.run {
            todos.append(Todo(id: tempId, title: title, is_complete: false))
            newTitle = ""
            addingFocused = false
        }

        do {
            // Insert and return the real row
            let inserted: Todo = try await client
                .from("todos")
                .insert(NewTodo(title: title, is_complete: false))
                .select()
                .single()
                .execute()
                .value


            await MainActor.run {
                if let i = todos.firstIndex(where: { $0.id == tempId }) {
                    todos[i] = inserted
                } else {
                    todos.append(inserted)
                }
            }
        } catch {
            // rollback placeholder on error
            await MainActor.run {
                todos.removeAll { $0.id == tempId }
            }
            print("addTodo error:", error)
        }

        await MainActor.run { isAdding = false }
    }
}
