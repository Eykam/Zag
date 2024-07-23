# Zag - An OSI Model Implementation
Welcome to Zag, a comprehensive project dedicated to implementing the entire OSI model, layer by layer. This project aims to provide a detailed and functional implementation of each layer of the network stack. For right now, this is a emulation of the network stack, using Raw Sockets from the C std library.

### Introduction
Zag will be an implementation of the bare mininum needed to comply with RFC / IEEE standards. I'll be implementing the most popular protocols in each layer. I'm planning on providing documentation, sources, and/or write ups about things I find useful while implementing the stack.

### Goals
- [ ] - Solve skill issues. 
- [ ] - Maybe learn about Zig, systems programming, and networking.
- [ ] - Make a custom VPN protocol built off of this library. 
- [ ] - write kernel modules that would be hotswappable with the default kernel network stack. 
- [ ] - Maybe play around with making own socket implementation ???
- [ ] - Make this a good resource for people looking to get into networking
  - [ ] - Easily follow along in your language of choice.

### Getting Started
To open Raw Sockets in the Linux kernel (and other OS's), you need `CAP_NET_RAW` capability. This can be done by either running the binary with root priviledges, or assigning the binary specific capabilities. To run the packet packet sniffer:
```
sudo zig build run
```
<b>IMPORTANT</b> : I also assume that the network interface you'd like to bind on is `eth0`.

You can change this default by setting INTERFACE at the top of main.zig, to any value you'd like. If you dont know what your network interface is, you can run this command on a linux machine: 
```
ip route show default | awk '/default/ {print $5}'
```
I'll likely provide binaries w/ a CLI in the future so you don't have to manually modify any files or build from source.

 
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
- [x] - I've currently implemented reading of ethernet frames
- [x] - Detection of Layer 3 Protocols
- [x] - Logging


### TODO
- Sending of ethernet frames
- Figure out what to do when frames > max_length || frames < min_length
- Implement parsing of IPv4 and IPv6 packets

<br>


### Contributing
Contributions are welcome! 


I'm new to Zig, so I still don't know the best practices. Feel free to reach out with any questions or suggestions. 

Stay Updated
Follow the project for updates on progress and new releases.

Twitter - https://x.com/AyeCaml <br>
Website - https://ekamil.sh