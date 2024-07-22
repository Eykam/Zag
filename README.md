Zag - An OSI Model Implementation
Welcome to Zag, a comprehensive project dedicated to implementing the entire OSI model, layer by layer. This project aims to provide a detailed and functional implementation of each layer of the network stack, offering insights and practical examples for educational and development purposes.

Introduction
Zag is a project that tackles the ambitious goal of implementing the entire OSI model. Each layer of the network stack will be meticulously crafted to provide a working example of how data is processed and transmitted from one layer to the next. The aim is to create a robust, educational tool for those interested in network protocols, operating systems, and low-level programming.

Goals
The primary goal of the Zag project is to deepen understanding and proficiency in Zig, systems programming, and networking. By working through each layer of the OSI model, the project will provide a hands-on learning experience that builds a strong foundation in these areas. Ultimately, the end goal is to leverage the knowledge and experience gained from this project to create a custom VPN protocol built off of this library.

OSI Model Overview
The OSI (Open Systems Interconnection) model is a conceptual framework used to understand and implement network protocols in seven layers. Each layer serves a specific function and communicates with the layers directly above and below it. Below is an overview of the OSI model:

```
+--------------------------------------+
|             Application              |
+--------------------------------------+
|             Presentation             |
+--------------------------------------+
|              Session                 |
+--------------------------------------+
|              Transport               |
+--------------------------------------+
|               Network                |
+--------------------------------------+
|               Data Link              |
+--------------------------------------+
|               Physical               |
+--------------------------------------+
```

Project Structure
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

Current Progress
Layer 2 - Data Link Layer
We are currently focused on implementing the Data Link Layer, which is responsible for node-to-node data transfer, error detection and handling, and framing. Specifically, we are working on a driver to parse Ethernet frames delivered by the Network Interface Card (NIC).

Current Tasks:

 Set up basic structure for Data Link Layer.
 Define interfaces for interacting with NIC drivers.
 Implement Ethernet frame parsing.
 Error detection and correction mechanisms.
 Frame delimitation and addressing.
Diagram: Ethernet Frame (IEEE 802.3)

```    
<------------------------------- Ethernet Frame --------------------------------->
    
    +------------+------------+---------+------+------+---------+----------------+
    | Preamble   | Start Frame| Dest    | Src  | Type/| Payload | Frame Check    |
    | (7 bytes)  | Delimiter  | MAC     | MAC  | Len  | (46-1500| Sequence (FCS) |
    |            | (1 byte)   | (6 bytes)|(6 bytes)|(2 bytes)| bytes)| (4 bytes)       |
    +------------+------------+---------+------+------+---------+----------------+
    
    <--------------------- 18 bytes ---------------><- Variable -><---- 4 bytes --->
    <-------------------------- 64 to 1518 bytes total -------------------------->
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

```bash
git clone https://github.com/yourusername/zag.git
cd zag
```
Contributing
Contributions are welcome! If you are interested in contributing to Zag, please read the CONTRIBUTING.md file for guidelines on how to get started. We are looking for developers with expertise in networking, low-level programming, and systems architecture.

License
This project is licensed under the MIT License. See the LICENSE file for details.

Feel free to reach out with any questions or suggestions. Happy coding!

Stay Updated
Follow the project for updates on progress and new releases. Let's build an amazing educational tool together!
