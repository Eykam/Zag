# Zag - An OSI Model Implementation
Welcome to Zag, a comprehensive project dedicated to implementing the entire OSI model, layer by layer. This project aims to provide a detailed and functional implementation of each layer of the network stack.

### Introduction
Zag will be an implementation of the bare mininum needed to comply with RFC / IEEE standards. I'll be implementing the most popular protocols in each layer. I'm planning on providing documentation, sources, and/or write ups about things I find useful while implementing the stack.

### Goals
The primary goal is to solve skill issues. Also maybe learn about Zig, systems programming, and networking. Would also be cool to make a custom VPN protocol built off of this library. Otherwise, I'd like to make this a good resource for people looking to get into networking. Hopefully if I document it well enough, people can easily follow along in their language of choice.

### Getting Started
To open Raw Sockets in the Linux kernel (and other OS's), you need `CAP_NET_RAW` capability. This can be done by either running the binary with root priviledges, or assigning the binary specific capabilities. To run the packet packet sniffer:
```
sudo zig build run
```
I'll likely provide a binary in the future so you don't have to build from source if you just want to try it out.

 
### OSI Model Overview
The OSI (Open Systems Interconnection) model is a conceptual framework used to understand and implement network protocols in seven layers. Each layer serves a specific function and communicates with the layers directly above and below it. Below is an overview of the OSI model:

```
+--------------------------------------+
|             Application              |
|             Custom VPN               |
+--------------------------------------+
|             Presentation             |
|             TLS / SSL                |
+--------------------------------------+
|              Session                 |
|              Custom                  |
+--------------------------------------+
|              Transport               |
|           TCP and/or UDP             |
+--------------------------------------+
|               Network                |
|            IP (v4 or v6)             |
+--------------------------------------+
|               Data Link              |
|     Ethernet or Wi-Fi (802.xx)       |
+--------------------------------------+
|               Physical               |
|     Ethernet or Wi-Fi (802.xx)       |
+--------------------------------------+

Explanation of the chosen protocols:

Application: TBD
Presentation: TDB
Transport: TCP for reliable communication 
    (e.g., control messages) and/or UDP for faster data transfer.
Network: IP (either v4 or v6) for routing packets across networks.
Data Link: Ethernet for wired connections or Wi-Fi for wireless, 
    depending on the physical medium.
Physical: The actual physical medium, which could be Ethernet cables 
    or Wi-Fi radio waves.
```

### Project Structure
The project is organized into directories corresponding to each OSI model layer. Each directory contains the source code and documentation for that specific layer.

```
zag/
├── layer1_physical/
├── layer2_datalink/
├── layer3_network/
├── layer4_transport/
├── layer5_session/
├── layer6_presentation/
└── layer7_application/
```

### Current Progress
Layer 2 - Data Link Layer
- I've currently implemented reading of ethernet frames


### Current Tasks:
- Need to implement LLC parsing
- Need to implement sending of ethernet frames

<br>

```    
<------------------------------- Ethernet Frame --------------------------------->
    
+------------+------------+---------+------+------+---------+----------------+
| Preamble   | Start Frame| Dest    | Src  | Type | Payload | Frame Check    |
|            | Delimiter  | MAC     | MAC  |      |         | Sequence (FCS) |
| 7b         | 1B         | 6B      | 6B   | 2B   | 46-1500B| 4B             |
+------------+------------+---------+------+------+---------+----------------+
    
<-------------------------- 64 to 1526 bytes total -------------------------->
** Need to confirm this **

Preamble: 7 octets of alternating 1s and 0s to synchronize the receiver.
SFD (Start Frame Delimiter): 1 octet signaling the start of the frame.
Destination Address: 6 octets identifying the frame's intended recipient.
Source Address: 6 octets identifying the sender.
Type/Length: 2 octets indicating the Ethernet type or payload length.
Payload: Data carried by the frame (46 to 1500 bytes).
FCS (Frame Check Sequence): 4 octets for error checking.
Getting Started
To get started with Zag, clone the repository and explore the documentation provided in each layer's directory. Ensure you have the required development environment set up as specified in the project documentation.
```



Contributing
Contributions are welcome! 


Feel free to reach out with any questions or suggestions. Happy coding!

Stay Updated
Follow the project for updates on progress and new releases. Let's build an amazing educational tool together!

Twitter - https://x.com/AyeCaml <br>
Website - https://ekamil.sh