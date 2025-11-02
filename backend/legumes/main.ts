import { Elysia, t } from "elysia";
import { createClient } from "@supabase/supabase-js";
import { cors } from "@elysiajs/cors";

const supabaseUrl = process.env.SUPABASE_URL!;
const supabaseRoleKey = process.env.SERVICEROLEKEY!;

const supabase = createClient(supabaseUrl, supabaseRoleKey);

const app = new Elysia();

//  Login
app.post(
  "/login",
  async ({ body }) => {
    const { email, password } = body;

    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (error) {
        if (error.message === "Email not confirmed") {
          return {
            success: false,
            error: "Please confirm your email before logging in",
          };
        }
        console.error("Error logging in:", error);
        return { success: false, error: error.message, details: error };
      }

      console.log("User logged in:", data);
      return { success: true, user: data.user, session: data.session };
    } catch (err) {
      console.error("Unexpected error:", err);
      return { success: false, error: "Internal server error", details: err };
    }
  },
  {
    body: t.Object({
      email: t.String(),
      password: t.String(),
    }),
  }
);

// ===========================
// 🟢 Endpoint: Créer un utilisateur (Admin ou Vendor)
// ===========================
app.post(
  "/user",
  async ({ body, headers, set }) => {
    const {
      email,
      password,
      name,
      roles,
      shop_name,
      phone,
      location,
      photo_url,
    } = body;

    // Get current user info from Authorization header
    const token = headers.authorization?.replace("Bearer ", "");
    const { data: userInfo, error: userInfoError } =
      await supabase.auth.getUser(token);

    if (userInfoError || !userInfo?.user) {
      set.status = 401;
      return { success: false, error: "Unauthorized" };
    }

    const currentUser = userInfo.user;
    const currentRoles = currentUser.user_metadata?.roles || [];
    const isAdmin = currentRoles.includes("admin");

    if (!isAdmin) {
      set.status = 403;
      return {
        success: false,
        error: "Only admins can create users with the role",
      };
    }

    try {
      // 1️⃣ Créer l'utilisateur dans Supabase Auth
      const { data: createdUser, error } = await supabase.auth.admin.createUser(
        {
          email,
          password,
          email_confirm: true,
          user_metadata: {
            name,
            roles,
          },
        }
      );

      if (error) {
        set.status = 400;
        return { success: false, error: error.message, details: error };
      }

      const userId = createdUser.user?.id;
      if (!userId) {
        set.status = 500;
        return { success: false, error: "User created but no ID returned" };
      }

      // 2️⃣ Insérer dans public.users
      const { error: userInsertError } = await supabase.from("users").insert([
        {
          id: userId,
          email,
          name,
        },
      ]);

      if (userInsertError) {
        set.status = 500;
        return {
          success: false,
          error: "Failed to insert into public.users",
          details: userInsertError.message,
        };
      }

      // 3️⃣ Insérer dans la table du rôle spécifique
      const role = roles[0]; // un seul rôle par utilisateur

      if (role === "admin") {
        await supabase.from("admin").insert([{ id: userId }]);
      } else if (role === "vendor") {
        await supabase.from("vendors").insert([
          {
            id: userId,
            shop_name,
            phone,
            location,
            photo_url,
          },
        ]);
      }

      // 4️⃣ Lier le rôle à l’utilisateur (dans user_roles)
      const { error: roleError } = await supabase.from("user_roles").insert([
        {
          user_id: userId,
          role_id: role,
        },
      ]);

      if (roleError) {
        set.status = 500;
        return {
          success: false,
          error: "Failed to insert user role",
          details: roleError.message,
        };
      }

      return {
        success: true,
        message: `User created successfully as ${role}`,
        user: { id: userId, email, name, role },
      };
    } catch (err) {
      console.error("Error creating user:", err);
      set.status = 500;
      return {
        success: false,
        error: "Internal server error",
        details: err instanceof Error ? err.message : JSON.stringify(err),
      };
    }
  },
  {
    body: t.Object({
      email: t.String(),
      password: t.String(),
      name: t.String(),
      roles: t.Array(t.String()), // ["admin"] or ["vendor"]
      shop_name: t.Optional(t.String()), // Vendor only
      phone: t.Optional(t.String()),
      location: t.Optional(t.String()),
      photo_url: t.Optional(t.String()),
    }),
  }
);
app.get("/check-email", async ({ query, set }) => {
  const { email } = query;
  if (!email || typeof email !== "string") {
    set.status = 400;
    return { exists: false, error: "Email manquant" };
  }

  try {
    const { data, error } = await supabase.auth.admin.listUsers();
    const userExists = data.users.some((user) => user.email === email);

    return { exists: userExists };
  } catch (e) {
    console.error("Erreur check-email:", e);
    set.status = 500;
    return { exists: false, error: "Erreur serveur" };
  }
});

app.post(
  "/register-public",
  async ({ body, set }) => {
    const { name, email, password, shop_name, phone, location, photo } = body;

    try {
      console.log("➡️ Début register-public");

      // 1️⃣ Créer un compte utilisateur avec rôle vendor
      const { data: createdUser, error: createError } =
        await supabase.auth.admin.createUser({
          email,
          password,
          email_confirm: true,
          user_metadata: { name, roles: ["vendor"] },
        });

      if (createError || !createdUser?.user?.id) {
        console.error("❌ Erreur création user:", createError);
        set.status = 400;
        return {
          success: false,
          error: createError?.message ?? "Erreur création utilisateur",
        };
      }

      const userId = createdUser.user.id;
      let photoUrl = null;

      // 2️⃣ Upload de la photo si présente
      if (photo && typeof photo !== "string") {
        const photoPath = `vendors/${userId}/${Date.now()}.jpg`;
        const { error: uploadError } = await supabase.storage
          .from("avatars")
          .upload(photoPath, photo, {
            contentType: photo.type,
            upsert: true,
          });

        if (uploadError) {
          set.status = 500;
          return {
            success: false,
            error: "Erreur lors du téléversement de la photo",
            details: uploadError.message,
          };
        }

        photoUrl = supabase.storage.from("avatars").getPublicUrl(photoPath)
          .data.publicUrl;
      }

      // 2️⃣ Insérer dans public.users
      const { error: userInsertError } = await supabase.from("users").insert([
        {
          id: userId,
          email,
          name,
        },
      ]);

      if (userInsertError) {
        set.status = 500;
        return {
          success: false,
          error: "Failed to insert into public.users",
          details: userInsertError.message,
        };
      }

      // 3️⃣ Insertion dans la table vendors
      const { error: insertError } = await supabase.from("vendors").insert({
        id: userId,
        shop_name,
        phone,
        location,
        photo_url: photoUrl,
        created_at: new Date().toISOString(),
      });

      if (insertError) {
        console.error("❌ Erreur insertion vendor:", insertError.message);
        set.status = 500;
        return { success: false, error: insertError.message };
      }

      // 4️⃣ Attribution du rôle vendor dans user_roles
      const { error: roleError } = await supabase
        .from("user_roles")
        .insert({ user_id: userId, role_id: "vendor" });

      if (roleError) {
        console.error("❌ Erreur ajout rôle:", roleError.message);
        set.status = 500;
        return { success: false, error: roleError.message };
      }

      // 5️⃣ Mise à jour des métadonnées
      await supabase.auth.admin.updateUserById(userId, {
        user_metadata: {
          name,
          roles: ["vendor"],
          photo: photoUrl,
        },
      });

      console.log("✅ Vendor créé avec succès:", userId);
      return { success: true, user_id: userId };
    } catch (e) {
      console.error("❌ Erreur serveur register-public:", e);
      set.status = 500;
      return { success: false, error: "Erreur interne du serveur" };
    }
  },
  {
    body: t.Object({
      name: t.String(),
      email: t.String(),
      password: t.String(),
      shop_name: t.String(),
      phone: t.Optional(t.String()),
      location: t.Optional(t.String()),
      photo: t.Optional(t.Union([t.File(), t.String()])),
    }),
  }
);

// ===========================
// 🔵 Endpoint: Liste des vendeurs
// ===========================
app.get("/vendor/list", async () => {
  const { data, error } = await supabase.from("vendors").select(`
    id,
    shop_name,
    phone,
    location,
    photo_url,
    created_at,
    users (name, email)
  `);

  if (error) return { success: false, error: error.message };
  return { success: true, data };
});

// ===========================
// 🟠 Endpoint: Mise à jour d’un vendeur
// ===========================
app.put(
  "/vendor/update/:id",
  async ({ params, body, set }) => {
    const { data, error } = await supabase
      .from("vendors")
      .update(body)
      .eq("id", params.id)
      .select("*");

    if (error) {
      set.status = 400;
      return { success: false, error: error.message };
    }

    return { success: true, data };
  },
  { params: t.Object({ id: t.String() }) }
);

// ===========================
// 🔴 Endpoint: Supprimer un vendeur
// ===========================
app.delete("/vendor/delete/:id", async ({ params, set }) => {
  const { error } = await supabase.from("vendors").delete().eq("id", params.id);

  if (error) {
    set.status = 400;
    return { success: false, error: error.message };
  }

  return { success: true, message: "Vendor deleted successfully" };
});

app.listen(4000);
console.log("🚀 API running on http://localhost:4000");
