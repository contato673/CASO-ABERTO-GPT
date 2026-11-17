(() => {
    let panel, form, submit, modeButton, message;
    let registering = false;

    function field(label, attrs) {
        const wrapper = document.createElement("label");
        wrapper.textContent = label;
        const input = document.createElement("input");
        Object.assign(input, attrs);
        wrapper.append(input);
        form.append(wrapper);
        return input;
    }

    window.bigFieldLogin = {
        mount(onSubmit, onMode) {
            panel = document.createElement("section");
            panel.id = "big-field-login";
            panel.setAttribute("aria-label", "Entrar no Big Field");
            const style = document.createElement("style");
            style.textContent = `
                body.big-field-auth { touch-action: auto; }
                #big-field-login { position: fixed; z-index: 100; inset: 0; overflow: auto;
                    box-sizing: border-box; min-width: 100%; background: #111820;
                    color: #f2eee4; font: 16px system-ui, sans-serif; touch-action: auto; }
                #big-field-login[hidden] { display: none; }
                #big-field-login form { width: min(440px, 100%); margin: 5vh auto 0;
                    padding: 24px; box-sizing: border-box; }
                #big-field-login h1 { color: #eec477; margin: 0 0 16px; }
                #big-field-login label { margin: 14px 0; display: block; }
                #big-field-login [hidden] { display: none; }
                #big-field-login input, #big-field-login button { display: block; box-sizing: border-box;
                    width: 100%; min-height: 46px; border-radius: 6px; border: 1px solid #71808a;
                    font: inherit; padding: 10px 12px; margin-top: 5px; color: inherit; background: #25313c; }
                #big-field-login button[type=submit] { background: #eec477; color: #171c21;
                    font-weight: 650; border-color: #eec477; }
                #big-field-login button:disabled { opacity: .58; }
                #big-field-login :focus-visible { outline: 2px solid #eec477; outline-offset: 2px; }
            `;
            document.head.append(style);
            form = document.createElement("form");
            panel.append(form);
            const title = document.createElement("h1");
            title.textContent = "Big Field";
            form.append(title);
            message = document.createElement("p");
            message.setAttribute("role", "status");
            form.append(message);
            const user = field("Usuário", {
                name: "username", autoComplete: "username", maxLength: 24,
                minLength: 3, pattern: "[a-zA-Z0-9_]{3,24}", required: true, spellcheck: false,
            });
            user.setAttribute("autocapitalize", "none");
            const password = field("Senha", {
                name: "password", type: "password", autoComplete: "current-password",
                minLength: 8, maxLength: 72, required: true,
            });
            const invite = field("Código de convite", {
                name: "invite", type: "password", autoComplete: "off", maxLength: 128,
            });
            submit = document.createElement("button");
            submit.type = "submit";
            form.append(submit);
            modeButton = document.createElement("button");
            modeButton.type = "button";
            form.append(modeButton);
            form.addEventListener("submit", event => {
                event.preventDefault();
                onSubmit(user.value, password.value, invite.value);
                password.value = "";
                invite.value = "";
                document.activeElement?.blur();
            });
            modeButton.addEventListener("click", () => onMode());
            for (const event of ["keydown", "keyup", "keypress"]) {
                panel.addEventListener(event, e => e.stopPropagation());
            }
            const viewport = window.visualViewport;
            if (viewport) {
                const fit = () => {
                    panel.style.height = viewport.height + "px";
                    panel.style.top = viewport.offsetTop + "px";
                };
                viewport.addEventListener("resize", fit);
                viewport.addEventListener("scroll", fit);
                fit();
            }
            document.body.append(panel);
            form.addEventListener("focusin", event => {
                const input = event.target;
                if (input instanceof HTMLInputElement) {
                    window.setTimeout(() => input.scrollIntoView({block: "nearest"}), 250);
                }
            });
            document.body.classList.add("big-field-auth");
            window.bigFieldLogin.update(false, "", false);
            return true;
        },
        update(create, text, busy) {
            registering = create;
            const invite = form.elements.namedItem("invite");
            invite.parentElement.hidden = !registering;
            invite.required = registering;
            form.elements.namedItem("password").autocomplete = registering ? "new-password" : "current-password";
            submit.textContent = registering ? "Criar conta e entrar" : "Entrar no Big Field";
            modeButton.textContent = registering ? "Já tenho conta" : "Tenho um convite";
            message.textContent = text;
            submit.disabled = busy;
            modeButton.disabled = busy;
        },
        show() {
            panel.hidden = false;
            document.body.classList.add("big-field-auth");
        },
        hide() {
            panel.hidden = true;
            document.body.classList.remove("big-field-auth");
            const canvas = document.getElementById("canvas");
            if (!navigator.maxTouchPoints) canvas?.focus({preventScroll: true});
        }
    };
})();
