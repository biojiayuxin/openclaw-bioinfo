import socket
import time

def hold_port(port=18789):
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    
    try:
        server_socket.bind(('0.0.0.0', port))
        server_socket.listen(1)
        print(f"端口 {port} 已被占用，按 Ctrl+C 释放...")
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\n释放端口...")
    except OSError as e:
        print(f"无法绑定端口 {port}: {e}")
    finally:
        server_socket.close()

if __name__ == '__main__':
    hold_port()
