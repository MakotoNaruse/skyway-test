<template>
    <div id="app">
        <template v-for="stream in remoteStreams">
            <!-- ①srcObjectをバインドする -->
            <video 
                autoplay 
                playsinline
                :srcObject.prop="stream"
            ></video>
        </template>
        <video id="my-video" muted="true" width="500" autoplay playsinline></video>
        <p>ROOM ID: <span id="room-id">{{ roomId }}</span></p>
        <button v-if="roomOpened === true" @click="leaveRoom" class="button--green">Leave</button>
        <button v-else @click="joinRoom" class="button--green">Join</button>
        <br />
        <div>
            マイク:
            <select v-model="selectedAudio" @change="onChange">
            <option disabled value="">Please select one</option>
            <option v-for="(audio, key, index) in audios" v-bind:key="index" :value="audio.value">
                {{ audio.text }}
            </option>
            </select>

            カメラ: 
            <select v-model="selectedVideo" @change="onChange">
            <option disabled value="">Please select one</option>
            <option v-for="(video, key, index) in videos" v-bind:key="index" :value="video.value">
                {{ video.text }}
            </option>
            </select>
        </div>

        <template v-for="message in messages">
            <p>{{message}}</p>
        </template>
    </div>
</template>

<script>
const API_KEY = "6f23e1ae-9d63-4719-9061-0d52daa71de4"; 
// const Peer = require('../skyway-js');
export default {
    data: function () {
        return {
            audios: [],
            videos: [],
            selectedAudio: '',
            selectedVideo: '',
            localStream: {},
            messages: [],
            roomId: "",
            remoteStreams: [],
            roomOpened: false
        }
    },
    methods: {
        // 端末のカメラ音声設定
        onChange: function(){
            if(this.selectedAudio != '' && this.selectedVideo != ''){
                this.connectLocalCamera();
            }
        },
        connectLocalCamera: async function(){
            const constraints = {
                audio: this.selectedAudio ? { deviceId: { exact: this.selectedAudio } } : false,
                video: this.selectedVideo ? { deviceId: { exact: this.selectedVideo } } : false
            }
            console.log(constraints);
            const stream = await navigator.mediaDevices.getUserMedia(constraints);
            document.getElementById('my-video').srcObject = stream;
            this.localStream = stream;
            console.log(stream);
        },
        leaveRoom: function(){
            if (!this.peer.open) {
                return;
            }
            this.roomOpened = false;
            this.room.close();
        },
        // 「div(joinTrigger)が押される＆既に接続が始まっていなかったら接続」するリスナーを設置
        joinRoom: function(){
            if (!this.peer.open) {
                return;
            }
            this.roomOpened = true;
            //部屋に接続するメソッド（joinRoom）
            this.room = this.peer.joinRoom(this.roomId, {
                mode: "sfu",
                stream: this.localStream,
            });
            this.room.replaceStream(this.localStream);
            //ログを出力
            this.room.once('log', logs => {
              for (const logStr of logs) {
                const { messageType, message, timestamp } = JSON.parse(logStr);
                console.log(messageType);
                console.log(message);
                console.log(timestamp);
              }
            });
            //部屋に接続できた時（open）に一度だけdiv(messages)に=== You joined ===を表示
            this.room.once('open', () => {
                this.messages.push('=== You joined ===');
                this.room.send("成瀬が参加しました");
                this.room.replaceStream(this.localStream);
                console.log("replacestream");
            });
            //部屋に誰かが接続してきた時（peerJoin）、いつでもdiv(messages)に下記のテキストを表示
            this.room.on('peerJoin', peerId => {
                this.messages.push(`=== ${peerId} joined ===`);
            });
            //重要：streamの内容に変更があった時（stream）videoタグを作って流す
            this.room.on('stream', async stream => {
                await this.remoteStreams.push(stream);
                this.room.replaceStream(this.localStream);
            });

            //重要：誰かがテキストメッセージを送った時、messagesを更新
            this.room.on('data', ({ data, src }) => {
                this.messages.push(`${src}: ${data}`);
            });

            // 誰かが退出した場合、div（remoteVideos）内にある、任意のdata-peer-idがついたvideoタグの内容を空にして削除する
            this.room.on('peerLeave', peerId => {
                const index = this.remoteStreams.findIndex((v) => v.peerId === peerId);
                const removedStream = this.remoteStreams.splice(index, 1);
                this.messages.push(`=== ${peerId} left ===`);
            });

            // 自分が退出した場合の処理 要改修
            this.room.once('close', () => {
                //メッセージ送信ボタンを押せなくする
                this.messages.length = 0;
            });
        }
    },

    created: async function(){
        const element = document.getElementById("room")
        const data = JSON.parse(element.getAttribute('data'))
        this.roomId = data.roomId
        //ここでpeerのリスナーを設置
        this.peer = new Peer({key: API_KEY, debug: 3}); //新規にPeerオブジェクトの作成

        //デバイスへのアクセス
        const deviceInfos = await navigator.mediaDevices.enumerateDevices();

        //オーディオデバイスの情報を取得
        deviceInfos
        .filter(deviceInfo => deviceInfo.kind === 'audioinput')
        .map(audio => this.audios.push({text: audio.label || `Microphone ${this.audios.length + 1}`, value: audio.deviceId}));

        //カメラの情報を取得
        deviceInfos
        .filter(deviceInfo => deviceInfo.kind === 'videoinput')
        .map(video => this.videos.push({text: video.label || `Camera  ${this.videos.length - 1}`, value: video.deviceId}));      
    }
}
</script>

<style scoped>
    p {
    font-size: 2em;
    text-align: center;
    }
</style>