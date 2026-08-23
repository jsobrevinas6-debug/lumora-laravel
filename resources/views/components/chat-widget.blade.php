<div x-data="chatWidget()" x-init="init()" style="position:fixed; bottom:24px; right:24px; z-index:999; font-family:'Poppins',sans-serif;">

    {{-- Floating bubble button --}}
    <button @click="open = !open" style="width:56px; height:56px; border-radius:50%; background:#5B1A35; color:#fff; border:none; box-shadow:0 6px 18px rgba(91,26,53,.35); cursor:pointer; font-size:24px; display:flex; align-items:center; justify-content:center;">
        <span x-show="!open">💬</span>
        <span x-show="open" style="display:none;">✕</span>
    </button>

    {{-- Chat panel --}}
    <div x-show="open" x-cloak style="position:absolute; bottom:70px; right:0; width:320px; height:420px; background:#fff; border-radius:16px; box-shadow:0 8px 30px rgba(0,0,0,.18); display:flex; flex-direction:column; overflow:hidden;">

        <div style="background:#5B1A35; color:#fff; padding:14px 16px; font-weight:700; font-size:14.5px;">
            Customer Support
        </div>

        <div x-ref="messageList" style="flex:1; overflow-y:auto; padding:14px; display:flex; flex-direction:column; gap:8px; background:#FBF1EC;">
            <template x-for="msg in messages" :key="msg.id">
                <div :style="msg.sender_id === userId
                    ? 'align-self:flex-end; background:#5B1A35; color:#fff; padding:8px 12px; border-radius:12px 12px 2px 12px; max-width:80%; font-size:13px;'
                    : 'align-self:flex-start; background:#fff; border:1px solid #F0E2DA; padding:8px 12px; border-radius:12px 12px 12px 2px; max-width:80%; font-size:13px;'">
                    <span x-text="msg.body"></span>
                </div>
            </template>
        </div>

        <form @submit.prevent="send()" style="display:flex; gap:8px; padding:10px; border-top:1px solid #F0E2DA;">
            <input x-model="newMessage" type="text" placeholder="Type a message..." style="flex:1; border:1px solid #F0E2DA; border-radius:20px; padding:8px 14px; font-size:13px; font-family:inherit;">
            <button type="submit" style="background:#5B1A35; color:#fff; border:none; border-radius:20px; padding:8px 16px; font-size:13px; cursor:pointer; font-family:inherit;">Send</button>
        </form>
    </div>
</div>

<script>
function chatWidget() {
    return {
        open: false,
        conversationId: null,
        userId: {{ auth()->id() ?? 'null' }},
        messages: [],
        newMessage: '',

        async init() {
            const res = await fetch('{{ route('chat.mine') }}', {
                headers: { 'Accept': 'application/json' }
            });
            const data = await res.json();
            this.conversationId = data.conversation_id;
            this.messages = data.messages;

            window.Echo.private('conversation.' + this.conversationId)
                .listen('.message.sent', (e) => {
                    this.messages.push(e);
                    this.$nextTick(() => this.scrollToBottom());
                });

            this.$nextTick(() => this.scrollToBottom());
        },

        async send() {
            if (!this.newMessage.trim()) return;

            const body = this.newMessage;
            this.newMessage = '';

            const res = await fetch('{{ route('chat.send') }}', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').getAttribute('content'),
                },
                body: JSON.stringify({ conversation_id: this.conversationId, body: body }),
            });

            const data = await res.json();

            this.messages.push({
                id: data.message_id,
                sender_id: this.userId,
                body: body,
                created_at: new Date().toISOString(),
            });

            this.$nextTick(() => this.scrollToBottom());
        },

        scrollToBottom() {
            this.$refs.messageList.scrollTop = this.$refs.messageList.scrollHeight;
        }
    }
}
</script>