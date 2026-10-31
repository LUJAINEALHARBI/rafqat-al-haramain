document.addEventListener("DOMContentLoaded", () => {

    /* =========================
        MOBILE MENU
    ========================= */
    const menuButton = document.querySelector(".menu-button");
    const navLinks = document.querySelector(".nav-links");

    if (menuButton && navLinks) {
        menuButton.addEventListener("click", () => {
            navLinks.classList.toggle("mobile-open");
        });
    }

    /* =========================
        LOGIN
        ملاحظة: التحقق من رقم العضوية وكلمة المرور انتقل إلى
        صفحة login.html نفسها، وصار يتم فعلياً عبر api/auth.php
        مقابل قاعدة البيانات. أُزيل الفحص القديم من هنا حتى لا
        يعمل مُعالِجان على نفس النموذج في وقت واحد.
    ========================= */
});

// دالة التبديل التفاعلي للتبويبات وغرف المحادثة
function switchChatRoom(roomId, btnElement) {
    const rooms = document.querySelectorAll('.chat-room-content');
    rooms.forEach(room => room.classList.remove('active'));

    const buttons = document.querySelectorAll('.chat-tab-btn');
    buttons.forEach(btn => btn.classList.remove('active'));

    const targetRoom = document.getElementById(roomId);
    if (targetRoom) {
        targetRoom.classList.add('active');
    }
    if (btnElement) {
        btnElement.classList.add('active');
    }
}

// دالة إرسال الرسالة المتوافقة 100% مع مسميات HTML لديك
function sendUserMessage(event) {
    event.preventDefault();
    const input = document.getElementById('chatMessageInput');
    if (!input) return;
    
    const text = input.value.trim();
    if (!text) return;

    const activeRoom = document.querySelector('.chat-room-content.active');
    if (!activeRoom) return;

    const msgDiv = document.createElement('div');
    msgDiv.className = 'message';
    msgDiv.style.marginBottom = '12px';
    msgDiv.style.padding = '12px';
    msgDiv.style.borderRadius = '8px';
    msgDiv.style.background = '#f1f3f4';
    msgDiv.innerHTML = `<strong>أنت (عضو نشط):</strong> <p style="margin: 5px 0 0;">${text}</p><span style="font-size:10px; color:#888;">الآن</span>`;

    activeRoom.appendChild(msgDiv);
    input.value = '';
    activeRoom.scrollTop = activeRoom.scrollHeight;
}

// التوافقية مع أي تبويبات أخرى في النظام
function switchTab(tabName) {
    const sections = document.querySelectorAll('.tab-section');
    sections.forEach(sec => sec.style.display = 'none');

    const target = document.getElementById(tabName);
    if (target) {
        target.style.display = 'block';
    }

    const buttons = document.querySelectorAll('.admin-tabs a, .chat-tab-btn');
    buttons.forEach(btn => btn.classList.remove('active'));
}