# Layer 2: Datalink

## IEEE 802 Ethernet Frame


## Receiving
A stream of analog signals, transferred from Layer 1 (Physical), is converted into digital data (stream of binary data) on the Network Interface Controller (NIC). 

The NIC monitors the stream of digital data, looking for the preamble. Once it detect the preamble and Start frame delimiter (SFD), it begins to read the remaining frame data (Figure 1).

```    
<------------------------------- NIC Ethernet Frame --------------------------------->
    
+------------+------------+---------+------+------+---------+----------------+
| Preamble   | Start Frame| Dest    | Src  | Type | Data    | Frame Check    |
|            | Delimiter  | MAC     | MAC  |      |         | Sequence (CRC) |
| 7b         | 1B         | 6B      | 6B   | 2B   | 46-1500B| 4B             |
+------------+------------+---------+------+------+---------+----------------+
<------------------- 22 bytes -------------------->    
<-------------------------- 72 to 1526 bytes total -------------------------->

```
Figure 1: Packet received by NIC.

As the frame is captured the data is transferred to the kernel (where we live). This can be implemented in many ways. For example, the NIC may have direct access to a shared buffer in main memory. The CPU is notified of the transfer, and runs network drivers. The Layer 2 network drivers will then process the shared buffer into the kernel Ethernet Frame (Figure 2). 


```    
<------------------------------- Kernel Ethernet Frame --------------------------------->
    
+---------+------+------+---------+----------------+
| Dest    | Src  | Type | Data    | Frame Check    |
| MAC     | MAC  |      |         | Sequence (CRC) |
| 6B      | 6B   | 2B   | 46-1500B| 4B             |
+---------+------+------+---------+----------------+
<------- 14 bytes ------>   
<------------- 64 to 1518 bytes total ------------->

```
Figure 2: Packet received by Kernel Raw Socket, this is what we will be working with in our drivers.


### Example Workflow:
The general idea is that Layer 2 will parse the protocol type, then pipe the data (and other necessary headers) to the appropriate Layer 3 Protocol-specific driver.

```
frame = Eth_Driver(raw_data) 
frame.type = IPv4 (Layer 3 protocol) 
IPv4_driver(frame)
   ^
protcol-specific driver

```
In this example, the L2 Protocol-specific Driver, Eth_Driver:
- parses the frame sent by the NIC
- determines protocol type of the frame
- forwards to protocol-specific driver

In this case, since we determined the frame had a type of IPv4, we call the IPv4 driver and pass it the frame for further propagation up the network stack. 


## Sending

coming soon...


## Stucture Fields



### Preamble: 

The preamble is primarily used at the physical layer (Layer 1) of the OSI model. It's typically handled by the network interface card (NIC) and is not passed up to the operating system or higher layers.

### Start Frame Delimiter (SFD):

- Size: 1 byte (8 bits)
- Value: Always 10101011 (0xAB in hexadecimal)
- Purpose: Signals the start of the frame content
- Position: Immediately follows the 7-byte preamble
- Not typically visible in kernel-level packet captures


### Destination MAC Address:

- Size: 6 bytes (48 bits)
- Format: Usually written as six groups of two hexadecimal digits, e.g., 00:1A:2B:3C:4D:5E
- Purpose: Identifies the intended recipient of the frame
- Special values:
  - FF:FF:FF:FF:FF:FF is the broadcast address
  - Addresses starting with 01:00:5E are for IPv4 multicast
  - Addresses starting with 33:33 are for IPv6 multicast



### Source MAC Address:

- Size: 6 bytes (48 bits)
- Format: Same as destination address
- Purpose: Identifies the sender of the frame
- Should be unique to the sending network interface


### - Type/Length:

- Size: 2 bytes (16 bits)
- Purpose: Indicates either the protocol type of the payload or the length of the payload
- Interpretation:
    - Values 1500 (0x05DC) and below: Indicates the length of the payload in bytes
    - Values above 1536 (0x0600): Indicates the protocol type of the payload
- Common EtherType values:
    - 0x0800: IPv4
    - 0x0806: ARP
    - 0x86DD: IPv6
    - 0x8100: VLAN-tagged frame (802.1Q)


### Data / Payload:

- Size: 46 to 1500 bytes (standard Ethernet)
- Minimum: 46 bytes (to ensure minimum frame size of 64 bytes)
- Maximum: 1500 bytes (can be larger for Jumbo frames)
- Purpose: Contains the actual data being transmitted
- Content: Typically contains higher-layer protocol data (e.g., IP packet, ARP request)
- Padding: If the data is less than 46 bytes, padding is added to reach the minimum size
- Encapsulation: This field often encapsulates the entire packet of the next layer protocol
- Flexibility: Can carry various types of data, determined by the EtherType field
- Processing: Interpreted based on the protocol specified in the EtherType field
- Security: May be encrypted if carrying secure protocols (e.g., IPsec)
- Fragmentation: Large payloads exceeding the maximum size must be fragmented at higher layers
- Visibility: Fully visible and accessible to software for processing and analysis
### Cyclic Redundancy Check (CRC) / Frame Check Sequence (FCS):

- Size: 4 bytes (32 bits)
- Purpose: Used to detect corruption in the frame during transmission
- Calculation: Computed over all fields of the frame except the preamble and SFD
- Property: If the frame is corrupted during transmission, the receiving station's CRC calculation will not match this value, indicating an error
- Not typically visible in software-level packet captures, as it's usually stripped off by the network interface hardware after verification



### Additional notes:

The order of these fields in an Ethernet frame is: SFD, Destination MAC, Source MAC, EtherType/Length, Payload, CRC.
The payload follows the EtherType/Length field and precedes the CRC. Its size can vary from 46 to 1500 bytes in standard Ethernet.
In software packet captures, you'll typically see the frame starting from the Destination MAC address, as the preamble, SFD, and CRC are usually handled by hardware.

This structure allows Ethernet to provide addressing, protocol identification or length specification, and error checking, forming the basis for reliable local area network communication.
