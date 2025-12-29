# ModBus Protocol Extensions

Technical documentation of WaterFurnace's proprietary ModBus extensions.

## Overview

WaterFurnace Aurora systems use ModBus RTU as the base protocol, but extend it with custom function codes for efficient bulk operations.

**Base Protocol:**
- ModBus RTU (binary format)
- Slave ID: 1 (ABC)
- 19200 baud, Even parity, 8 data bits, 1 stop bit

**Custom Extensions:**
- Function 65: Read multiple discontiguous ranges
- Function 66: Read multiple discontiguous registers
- Function 67: Write multiple discontiguous registers
- Function 68: Unknown purpose

## Standard ModBus Functions

The ABC supports standard ModBus functions:

### Function 3: Read Holding Registers

**Request:**
```
Slave ID: 1 byte
Function: 1 byte (0x03)
Start Address: 2 bytes (big-endian)
Quantity: 2 bytes (big-endian)
CRC: 2 bytes
```

**Response:**
```
Slave ID: 1 byte
Function: 1 byte (0x03)
Byte Count: 1 byte
Register Values: N bytes (2 bytes per register, big-endian)
CRC: 2 bytes
```

**Example:**
```
Request:  01 03 02 E9 00 03 [CRC]  # Read 3 registers starting at 745
Response: 01 03 06 02 A8 02 DA 02 DA [CRC]  # Values: 680, 730, 730
```

### Function 6: Write Single Register

**Request:**
```
Slave ID: 1 byte
Function: 1 byte (0x06)
Register Address: 2 bytes (big-endian)
Register Value: 2 bytes (big-endian)
CRC: 2 bytes
```

**Response:** Echo of request

### Function 16: Write Multiple Registers

**Request:**
```
Slave ID: 1 byte
Function: 1 byte (0x10)
Start Address: 2 bytes
Quantity: 2 bytes
Byte Count: 1 byte
Register Values: N bytes
CRC: 2 bytes
```

## Custom Function 65: Read Multiple Ranges

**Purpose:** Read multiple discontiguous register ranges in a single request.

This is WaterFurnace's primary optimization - instead of many Function 3 requests, one Function 65 request can query multiple ranges.

**Request Format:**
```
Slave ID: 1 byte (0x01)
Function: 1 byte (0x41 = 65)
Range Count: 1 byte
Ranges: 4 bytes per range
  - Start Address: 2 bytes (big-endian)
  - Quantity: 2 bytes (big-endian)
CRC: 2 bytes
```

**Response Format:**
```
Slave ID: 1 byte (0x01)
Function: 1 byte (0x41 = 65)
Byte Count: 1 byte
Register Values: N bytes (all ranges concatenated)
CRC: 2 bytes
```

**Example:**

Read registers 745-747 and 1110-1111:

```
Request:
01 41 02          # Slave 1, Function 65, 2 ranges
02 E9 00 03       # Range 1: Start 745, Quantity 3
04 56 00 02       # Range 2: Start 1110, Quantity 2
[CRC]

Response:
01 41 0A          # Slave 1, Function 65, 10 bytes
02 A8 02 DA 02 DA # Range 1 values: 680, 730, 730
03 BB 03 6E       # Range 2 values: 955, 878
[CRC]
```

**Limitations:**
- Maximum ~100 total registers per request
- ABC may reject oversized requests

## Custom Function 66: Read Discontiguous Registers

**Purpose:** Read specific individual registers (not ranges) in a single request.

**Request Format:**
```
Slave ID: 1 byte (0x01)
Function: 1 byte (0x42 = 66)
Register Count: 1 byte
Register Addresses: 2 bytes each (big-endian)
CRC: 2 bytes
```

**Response Format:**
```
Slave ID: 1 byte (0x01)
Function: 1 byte (0x42 = 66)
Byte Count: 1 byte
Register Values: 2 bytes per register
CRC: 2 bytes
```

**Example:**

Read registers 2, 745, 1110:

```
Request:
01 42 03          # Slave 1, Function 66, 3 registers
00 02             # Register 2
02 E9             # Register 745
04 56             # Register 1110
[CRC]

Response:
01 42 06          # Slave 1, Function 66, 6 bytes
01 46             # Register 2: 326 (ABC version 3.26)
02 A8             # Register 745: 680 (68.0°F)
03 BB             # Register 1110: 955 (95.5°F)
[CRC]
```

## Custom Function 67: Write Discontiguous Registers

**Purpose:** Write to multiple non-consecutive registers in a single request.

**Request Format:**
```
Slave ID: 1 byte (0x01)
Function: 1 byte (0x43 = 67)
Pair Count: 1 byte
Address-Value Pairs: 4 bytes each
  - Register Address: 2 bytes (big-endian)
  - Register Value: 2 bytes (big-endian)
CRC: 2 bytes
```

**Response Format:**
```
Slave ID: 1 byte (0x01)
Function: 1 byte (0x43 = 67)
Pair Count: 1 byte (echo)
CRC: 2 bytes
```

**Example:**

Write 720 to register 745, 680 to register 746:

```
Request:
01 43 02          # Slave 1, Function 67, 2 pairs
02 E9 02 D0       # Register 745 = 720
02 EA 02 A8       # Register 746 = 680
[CRC]

Response:
01 43 02          # Slave 1, Function 67, 2 pairs confirmed
[CRC]
```

## Custom Function 68: Unknown

**Purpose:** Unknown - rarely observed.

**Request Format:**
```
Slave ID: 1 byte (0x01)
Function: 1 byte (0x44 = 68)
Data: 4 bytes (purpose unknown)
CRC: 2 bytes
```

**Response Format:**
```
Slave ID: 1 byte (0x01)
Function: 1 byte (0x44 = 68)
Data: 1 byte (purpose unknown)
CRC: 2 bytes
```

**Status:** Not implemented in this library. If you observe this function in use, please report it!

## Implementation

### In This Library

The custom functions are implemented in:
- `lib/aurora/modbus/server.rb` - Server-side (for mock ABC)
- `lib/aurora/modbus/slave.rb` - Client-side (for querying ABC)

**Key Class:** `WFProxy`

Extends RModBus::RTUClient with:
```ruby
def read_multiple_holding_registers(addresses)
  # Uses Function 65 or 66 depending on input format
end
```

### Usage Example

```ruby
require 'aurora'

abc = Aurora::ABCClient.new('/dev/ttyUSB0')

# Automatically uses Function 65 for ranges
data = abc.modbus_slave.read_holding_registers(745, 3)
# Sends: Function 65 with one range: 745-747

# Automatically uses Function 66 for discontiguous
data = abc.modbus_slave.read_multiple_holding_registers([2, 745, 1110])
# Sends: Function 66 with three addresses
```

## Register Organization

### Valid Ranges

Not all register addresses are valid. The ABC only responds to specific ranges (see [registers.md](registers.md)):

```ruby
REGISTER_RANGES = [
  0..49,
  50..99,
  100..149,
  # ... (21 ranges total)
  61_000..61_009
].freeze
```

Querying outside these ranges results in timeout or error.

### Read Optimization

When querying large ranges, the library:

1. Breaks at register breakpoints (registers that often timeout)
2. Limits to 100 registers per request
3. Falls back to individual reads on timeout

**Breakpoints:**
```ruby
REGISTER_BREAKPOINTS = [
  280, 400, 567, 813, 1104
].freeze
```

These registers often timeout, so queries are split around them.

## Timing and Retry

### Timeouts

Default: 15 seconds per request

**Rationale:**
- ABC can be slow when system is busy
- Some registers take longer than others
- Network latency (if using TCP/RFC2217)

### Retry Logic

The library doesn't automatically retry. Tools like `aurora_fetch` handle retries at application level:

```ruby
begin
  value = abc.modbus_slave.read_holding_registers(address, 1)
rescue Timeout::Error
  # Retry or skip
end
```

## Error Handling

### ModBus Exceptions

Standard ModBus exception codes:
- 0x01: Illegal Function
- 0x02: Illegal Data Address
- 0x03: Illegal Data Value
- 0x04: Slave Device Failure

**ABC Behavior:**
- Invalid registers: Usually timeout (no response)
- Valid but inapplicable registers: May return 0 or timeout
- Out-of-range values: May accept silently (no validation)

### CRC Errors

ModBus RTU uses CRC-16 for error detection. The RModBus library handles CRC automatically.

Persistent CRC errors indicate:
- Electrical interference
- Poor cable quality
- Incorrect baud/parity settings
- Faulty RS-485 adapter

## Performance Characteristics

### Throughput

**Serial (19200 baud):**
- ~1920 bytes/second theoretical
- ~1000 bytes/second practical (overhead)

**Query rates:**
- Single register: ~100ms
- 10 registers (one range): ~150ms
- 100 registers (Function 65): ~500ms

**Bottleneck:** Serial baud rate, not processing

### Concurrency

ModBus RTU is strictly sequential:
- One request at a time
- Wait for response before next request
- No pipelining

**Implication:** Tools must serialize access to serial port.

## Packet Capture

### Using aurora_monitor

The easiest way to capture ModBus traffic:

```bash
aurora_monitor /dev/ttyUSB0 -q
```

Decodes packets automatically.

### Raw Capture

For low-level analysis:

```bash
# Requires in-line connection
cat /dev/ttyUSB0 | xxd
```

Or use Wireshark with ModBus dissector (TCP only).

## Comparison to Standard ModBus

### Advantages of Custom Functions

**Function 65 vs. multiple Function 3:**
- Fewer round-trips
- Lower latency
- More efficient use of bandwidth

**Example:**

Query 10 non-consecutive registers:

**Standard ModBus (Function 3):**
- 10 requests × 150ms = 1500ms
- 10× request overhead

**Custom ModBus (Function 66):**
- 1 request × 200ms = 200ms
- Single request overhead

**7.5× faster!**

### Disadvantages

- Non-standard (not compatible with generic ModBus tools)
- Requires custom client implementation
- Undocumented (reverse-engineered)

## Security Considerations

### No Authentication

ModBus RTU has **no authentication**:
- Anyone with physical access can query/control
- No password protection
- No user management

**Mitigation:** Physical security, network isolation

### No Encryption

All traffic is plaintext:
- Register values visible on wire
- Commands observable
- Man-in-the-middle possible

**Mitigation:** Use VPN/SSH tunnel for network connections

### No Authorization

All registers have same access level:
- Read any readable register
- Write any writable register
- No role-based access

**Mitigation:** Application-layer access control (MQTT auth, web proxy)

## Further Reading

- [ModBus Protocol Specification](https://modbus.org/docs/Modbus_Application_Protocol_V1_1b3.pdf)
- [ModBus RTU Serial Transmission](https://modbus.org/docs/Modbus_over_serial_line_V1_02.pdf)
- [RModBus Library Documentation](https://github.com/flipback/rmodbus)

## Contributing

If you discover:
- New custom function codes
- Additional Function 68 details
- Protocol quirks or behaviors
- Performance optimizations

Please share via GitHub issue or pull request!

## Related Documentation

- [Register Reference](registers.md) - Known register addresses
- [Reverse Engineering](reverse-engineering.md) - Discover new registers
- [aurora_monitor](../tools/aurora_monitor.md) - Traffic analysis tool
