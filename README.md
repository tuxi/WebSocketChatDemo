### Web socket chat demo


### 两种机制保证WebSocket 连接不断开
- 失败重连机制
- 心跳包ping pong机制，
发送的ping和接收的pong在一定时间后，需保持一致，如果不一致则认为服务器已断开连接，此时客户端重连。
