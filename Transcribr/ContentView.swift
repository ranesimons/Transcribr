//
//  ContentView.swift
//  Transcribr
//
//  Created by Rane Simons on 9/4/21.
//

import SwiftUI

import SocketIO

final class Service: ObservableObject {
    private var manager = SocketManager(socketURL: URL(string: "ws://localhost:3000")!, config: [.log(true), .compress])
    
    @Published var messages = [String]()
    
    init() {
        let socket = manager.defaultSocket
        socket.on(clientEvent: .connect) { (data, ack) in
            print("Connected")
            socket.emit("Node JS Server Port", "Hi Node.JS server!")
        }

        socket.on("iOS Client Port") { [weak self] (data, ack) in
            if let data = data[0] as? [String: String],
               let rawMessage = data["msg"] {
                DispatchQueue.main.async {
                    self?.messages.append(rawMessage)
                }
            }
        }
        
        socket.connect()
    }
}

struct ContentView: View {
    @ObservedObject var service = Service()
    var body: some View {
        VStack {
            Text("Received messages from Node.js").font(.largeTitle)
            ForEach(service.messages, id: \.self) { msg in
                Text(msg).padding()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
