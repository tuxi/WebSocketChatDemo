### iOS  WebSocket 聊天示例
基于SocketRocket 构建的WebSocket  聊天示例，本项目注重点在于客户端和服务端的WebSocket通讯，目前已实现简单的用户系统、一对一聊天。

- 自建的WebSocket 服务端项目 https://github.com/tuxi/websocket_server

- Api 文档 https://chat.enba.com/api/docs/

- Web 端测试 https://chat.enba.com/

下图为web前端与iOS 聊天的演示
![websocket client](https://static.objc.com/enba/static/websocketclient.gif)

- [测试](https://chat.enba.com/test/)用户

username | password
:-: | :-: 
user1 | password123 | 
user2 | password123 | 


### 已完成的模块
- 用户
- 文本聊天

### 两种机制保证WebSocket 连接不断开
- 失败重连机制
当代理收到失败或者close的回调时，根据实际请求启动重连机制。
- 心跳包ping pong机制
WebSocket 连接打开后，开启心跳包机制发送ping，发送的ping和接收的pong在一定时间内，需保持一致，如果不一致则认为服务器已断开连接，此时客户端断开重连。

### 正在输入机制
- 监听输入框发生改变的通知，并通过WebSocket发送`is-typing`的消息给对方，服务端收到后将消息分发给对方
- 客户端收到`opponent-typing`的消息后，延迟1秒更新UI为正在输入状态，如果1秒后未收到`opponent-typing`消息则取消正在输入状态
