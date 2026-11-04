/* =====================================================================
   api.js — حلقة الوصل بين صفحات الموقع وقاعدة البيانات
   ---------------------------------------------------------------------
   كل صفحة تستدعي الدوال هنا، وهذه الدوال ترسل الطلب لملفات PHP
   داخل مجلد api/ ، وملفات PHP هي وحدها التي تتصل بقاعدة البيانات.

   مهم: لا توجد أي بيانات اتصال بقاعدة البيانات في هذا الملف
        ولا في أي ملف يصل للمتصفح.
   ===================================================================== */

const API = {

    base: 'api/',

    /** طلب قراءة (GET) */
    async get(file, action, params = {}) {
        const qs = new URLSearchParams({ action, ...params }).toString();
        return API._send(`${API.base}${file}?${qs}`, { method: 'GET' });
    },

    /** طلب كتابة (POST) — يرسل JSON */
    async post(file, action, data = {}) {
        return API._send(`${API.base}${file}?action=${encodeURIComponent(action)}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        });
    },

    /** طلب كتابة مع ملف مرفق (FormData) */
    async postForm(file, action, formData) {
        return API._send(`${API.base}${file}?action=${encodeURIComponent(action)}`, {
            method: 'POST',
            body: formData
        });
    },

    async _send(url, options) {
        options.credentials = 'same-origin';   // ترسل كوكي الجلسة
        let res, body;
        try {
            res = await fetch(url, options);
        } catch (e) {
            throw new Error('تعذّر الوصول إلى الخادم. تأكد أن Apache يعمل وأن الموقع مفتوح عبر http://localhost وليس بفتح الملف مباشرة.');
        }

        const text = await res.text();
        try {
            body = JSON.parse(text);
            sessionStorage.removeItem('hostCheckReloaded');
        } catch (e) {
            // استضافة InfinityFree ترد أحياناً بصفحة تحقق أمني (aes.js) بدل نتيجة الطلب.
            // المتصفح وحده يستطيع إكمال هذا التحقق، و fetch لا يستطيع،
            // لذلك نعيد تحميل الصفحة مرة واحدة ليكمله المتصفح بشكله الطبيعي.
            if (/aes\.js|slowAES|toNumbers/.test(text)) {
                if (!sessionStorage.getItem('hostCheckReloaded')) {
                    sessionStorage.setItem('hostCheckReloaded', '1');
                    location.reload();
                }
                throw new Error('انتهت جلسة التحقق الأمني للاستضافة. حدّثي الصفحة ثم أعيدي المحاولة.');
            }
            throw new Error('رد غير متوقع من الخادم:\n' + text.slice(0, 300));
        }

        if (!res.ok || body.ok === false) {
            const err = new Error(body.error || 'حدث خطأ غير متوقع.');
            err.status  = res.status;
            err.details = body.details;
            throw err;
        }
        return body;
    },

    /* ---------------------------------------------------------------
       المستخدم الحالي
       --------------------------------------------------------------- */

    _user: undefined,

    /** يرجع بيانات المستخدم المسجّل دخوله، أو null */
    async me() {
        if (API._user !== undefined) return API._user;
        try {
            const r = await API.get('auth.php', 'me');
            API._user = r.data;
        } catch (e) {
            API._user = null;
        }
        return API._user;
    },

    /**
     * تتأكد أن المستخدم مسجّل دخول وأن دوره مسموح،
     * وإلا تعيده لصفحة تسجيل الدخول.
     */
    async requireLogin(roles = []) {
        const user = await API.me();
        if (!user) {
            window.location.href = 'login.html';
            return null;
        }
        if (roles.length && !roles.includes(user.role)) {
            alert('هذه الصفحة ليست ضمن صلاحياتك.');
            window.location.href = 'index.html';
            return null;
        }
        return user;
    },

    async logout() {
        try { await API.post('auth.php', 'logout'); } catch (e) { /* تجاهل */ }
        API._user = null;
        sessionStorage.clear();
        window.location.href = 'login.html';
    },

    /* ---------------------------------------------------------------
       تكييف الواجهة حسب نوع المستخدم
       ---------------------------------------------------------------
       كل صفحة تعرض عناصرها حسب دور المستخدم وصلاحيات وظيفته،
       فلا يظهر للحاج زر إداري ولا يظهر لموظف الإعاشة قسم طبي.

       الاستخدام في HTML:
         data-roles="pilgrim supervisor"   يظهر لهذه الأدوار فقط
         data-hide-roles="pilgrim"         يختفي عن هذه الأدوار
         data-perm="manage_journey"        يظهر لمن يملك هذه الصلاحية
         data-jobs="medical crowd"         يظهر لهذه الوظائف فقط
       --------------------------------------------------------------- */

    /** هل يملك المستخدم الحالي هذه الصلاحية؟ */
    can(permission, user = API._user) {
        const list = (user && user.permissions) || [];
        return list.indexOf(permission) !== -1;
    },

    /** يخفي من الصفحة كل ما لا يخص هذا المستخدم */
    applyRoleUI(user) {
        if (!user) return;

        const role = user.role || '';
        const job  = user.job_role || '';
        const list = (s) => String(s || '').split(/[\s,]+/).filter(Boolean);

        document.body.setAttribute('data-user-role', role);
        if (job) document.body.setAttribute('data-user-job', job);

        document.querySelectorAll('[data-roles]').forEach(el => {
            if (list(el.dataset.roles).indexOf(role) === -1) el.style.display = 'none';
        });

        document.querySelectorAll('[data-hide-roles]').forEach(el => {
            if (list(el.dataset.hideRoles).indexOf(role) !== -1) el.style.display = 'none';
        });

        document.querySelectorAll('[data-jobs]').forEach(el => {
            if (list(el.dataset.jobs).indexOf(job) === -1) el.style.display = 'none';
        });

        document.querySelectorAll('[data-perm]').forEach(el => {
            const needed = list(el.dataset.perm);
            const allowed = needed.some(p => API.can(p, user));
            if (!allowed) el.style.display = 'none';
        });

        /* أماكن تُكتب فيها بيانات المستخدم مباشرة */
        document.querySelectorAll('[data-user-field]').forEach(el => {
            const value = user[el.dataset.userField];
            if (value !== undefined && value !== null) el.innerText = value;
        });
    },

    /* ---------------------------------------------------------------
       أدوات صغيرة
       --------------------------------------------------------------- */

    /** يمنع ظهور وسوم HTML قادمة من قاعدة البيانات داخل الصفحة */
    esc(value) {
        if (value === null || value === undefined) return '';
        return String(value)
            .replace(/&/g, '&amp;').replace(/</g, '&lt;')
            .replace(/>/g, '&gt;').replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    },

    /** يعرض رسالة خطأ بشكل موحّد */
    showError(err, fallback = 'حدث خطأ.') {
        console.error(err);
        alert(err && err.message ? err.message : fallback);
    },

    /** صف "جاري التحميل" أو "لا توجد بيانات" داخل جدول */
    tableMessage(tbody, colspan, text) {
        if (!tbody) return;
        tbody.innerHTML =
            `<tr><td colspan="${colspan}" style="text-align:center; color:#777; padding:18px;">${API.esc(text)}</td></tr>`;
    }
};

/* زر تسجيل الخروج المشترك في كل الصفحات */
function logoutUser()       { if (confirm('هل تريد تسجيل الخروج؟')) API.logout(); }
function logoutAdmin()      { logoutUser(); }
function logoutSupervisor() { logoutUser(); }
function logoutCampaign()   { logoutUser(); }
