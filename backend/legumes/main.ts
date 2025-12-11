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
      const attributes: { [key: string]: any } = {};
      if (roles[0] === "consumer") {
        attributes.phone = phone;
      } else {
        attributes.email = email;
        attributes.password = password;
      }

      const { data: createdUser, error } = await supabase.auth.admin.createUser(
        {
          ...attributes,
          user_metadata: { name, roles },
          email_confirm: true,
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
          email: email || null,
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
      const role = roles[0];
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
      } else if (role === "consumer") {
        await supabase.from("consumers").insert([
          {
            id: userId,
            name,
            phone,
            location,
            created_at: new Date().toISOString(),
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
        user: { id: userId, name, role },
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
      email: t.Optional(t.String()), // Maintenant optionnel
      password: t.Optional(t.String()), // Maintenant optionnel
      name: t.String(),
      roles: t.Array(t.String()), // ["consumer"] or ["vendor"] or ["admin"]
      shop_name: t.Optional(t.String()), // Vendor only
      phone: t.Optional(t.String()), // Consumer/vendor
      location: t.Optional(t.String()), // Consumer/vendor
      photo_url: t.Optional(t.String()), // Vendor
    }),
  }
);

// Ajoute cet endpoint dans ton serveur (Hono, Express, etc.)

app.post(
  "/consumer",
  async ({ body, set }) => {
    const { name, phone, location } = body;

    try {
      // 1. Créer l'utilisateur dans auth.users (avec phone)
      const { data: authUser, error: authError } =
        await supabase.auth.admin.createUser({
          phone,
          user_metadata: {
            name,
            role: "consumer",
            location,
          },
          phone_confirm: true, // Si tu veux que le numéro soit confirmé automatiquement
        });

      if (authError) {
        console.error("Erreur création auth.users:", authError);
        set.status = 400;
        return { success: false, error: authError.message };
      }

      const userId = authUser.user.id;

      // 2. Insérer dans public.users
      const { error: publicError } = await supabase.from("users").insert({
        id: userId,
        name,
        email: null,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      });

      if (publicError) {
        console.error("Erreur public.users:", publicError);
        set.status = 500;
        return { success: false, error: "Échec insertion public.users" };
      }

      // 3. Insérer dans consumers
      const { error: consumerError } = await supabase.from("consumers").insert({
        id: userId,
        name,
        phone,
        location,
        created_at: new Date().toISOString(),
      });

      if (consumerError) {
        console.error("Erreur consumers:", consumerError);
        set.status = 500;
        return { success: false, error: "Échec insertion consumers" };
      }

      // 4. Insérer le rôle dans user_roles
      const { error: roleError } = await supabase.from("user_roles").insert({
        id: crypto.randomUUID(), // ou gen_random_uuid() si tu as l'extension
        user_id: userId,
        role_id: "consumer",
      });

      if (roleError) {
        console.error("Erreur user_roles:", roleError);
        set.status = 500;
        return { success: false, error: "Échec insertion rôle" };
      }

      return {
        success: true,
        message: "Consumer créé avec succès",
        user: {
          id: userId,
          name,
          phone,
          location,
        },
      };
    } catch (err) {
      console.error("Erreur inattendue:", err);
      set.status = 500;
      return { success: false, error: "Erreur serveur" };
    }
  },
  {
    body: t.Object({
      name: t.String(),
      phone: t.Optional(t.String()), // Consumer/vendor
      location: t.Optional(t.String()), // Consumer/vendor
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
// Route : POST /vendor/delete
app.post(
  "/vendor/delete",
  async ({ body, set }) => {
    const { id } = body as { id: string };

    if (!id) {
      set.status = 400;
      return { success: false, error: "ID du vendeur manquant" };
    }

    try {
      console.log(`Début suppression vendeur ID: ${id}`);

      // 1. Supprimer le rôle (user_roles)
      const { error: roleError } = await supabase
        .from("user_roles")
        .delete()
        .eq("user_id", id);

      if (roleError) {
        console.error("Erreur suppression user_roles:", roleError);
        set.status = 500;
        return {
          success: false,
          error: "Impossible de supprimer le rôle",
          details: roleError.message,
        };
      }
      console.log("Supprimé de user_roles");

      // 2. Supprimer les données spécifiques au vendeur
      const { error: vendorError } = await supabase
        .from("vendors")
        .delete()
        .eq("id", id);

      if (vendorError) {
        console.error("Erreur suppression vendors:", vendorError);
        set.status = 500;
        return {
          success: false,
          error: "Impossible de supprimer le profil vendeur",
          details: vendorError.message,
        };
      }
      console.log("Supprimé de vendors");

      // 3. Supprimer l'utilisateur dans la table users
      const { error: usersError } = await supabase
        .from("users")
        .delete()
        .eq("id", id);

      if (usersError) {
        console.error("Erreur suppression users:", usersError);
        set.status = 500;
        return {
          success: false,
          error: "Impossible de supprimer l'utilisateur",
          details: usersError.message,
        };
      }
      console.log("Supprimé de users");

      // 4. Supprimer l'utilisateur dans auth.users (le plus important !)
      const { error: authError } = await supabase.auth.admin.deleteUser(id);

      if (authError) {
        console.error("Erreur suppression auth.users:", authError);
        set.status = 500;
        return {
          success: false,
          error: "Impossible de supprimer le compte authentifié",
          details: authError.message,
        };
      }
      console.log("Supprimé de auth.users");

      return {
        success: true,
        message: "Vendeur supprimé avec succès",
        user_id: id,
      };
    } catch (e: any) {
      console.error("Erreur inattendue lors de la suppression du vendeur:", e);
      set.status = 500;
      // // return {
      //   success: false,
      //   error: "Erreur serveur",
      return { success: false, error: "Erreur serveur interne" };
      // };
    }
  },
  {
    body: t.Object({
      id: t.String({ format: "uuid" }), // Optionnel : valide que c’est un UUID
    }),
  }
);

// === 1. Créer un produit (Vendor only) ===
app.post(
  "/product/create",
  async ({ body, headers, set }) => {
    const { name, price, quantity, image_url, date } = body;

    // Auth
    const token = headers.authorization?.replace("Bearer ", "");
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser(token);
    if (authError || !user) {
      set.status = 401;
      return { success: false, error: "Unauthorized" };
    }

    const roles = user.user_metadata?.roles || [];
    if (!roles.includes("vendor") && !roles.includes("admin")) {
      set.status = 403;
      return {
        success: false,
        error: "Seul un vendeur peut ajouter un produit",
      };
    }

    const vendor_id = user.id;

    const { data, error } = await supabase
      .from("products")
      .insert({
        vendor_id,
        name,
        price: parseFloat(price),
        quantity: parseInt(quantity),
        image_url: image_url || null, // On accepte juste l’URL (string)
        date: date || new Date().toISOString().split("T")[0],
      })
      .select()
      .single();

    if (error) {
      set.status = 400;
      return { success: false, error: error.message };
    }

    return { success: true, product: data };
  },
  {
    body: t.Object({
      name: t.String(),
      price: t.String(),
      quantity: t.String(),
      image_url: t.Optional(t.String()), // URL publique
      date: t.Optional(t.String()),
    }),
  }
);

// === 2. Récupérer les produits d’un vendeur ===
app.get("/product/vendor/:id", async ({ params, headers, set }) => {
  const { id } = params;

  const { data, error } = await supabase
    .from("products")
    .select("*, vendor:vendors(shop_name, photo_url)")
    .eq("vendor_id", id)
    .order("created_at", { ascending: false });

  if (error) {
    set.status = 400;
    return { success: false, error: error.message };
  }

  return { success: true, products: data || [] };
});

// === 3. Mettre à jour un produit (seul le propriétaire) ===
app.put("/product/update/:id", async ({ params, body, headers, set }) => {
  const { id } = params;

  // === Authentification ===
  const token = headers.authorization?.replace("Bearer ", "");
  const {
    data: { user },
    error: authError,
  } = await supabase.auth.getUser(token);
  if (authError || !user) {
    set.status = 401;
    return { success: false, error: "Unauthorized" };
  }

  // === Vérifier que le produit appartient au vendeur ===
  const { data: product, error: fetchError } = await supabase
    .from("products")
    .select("vendor_id")
    .eq("id", id)
    .single();

  if (fetchError || !product) {
    set.status = 404;
    return { success: false, error: "Produit non trouvé" };
  }

  const isOwner = product.vendor_id === user.id;
  const isAdmin = user.user_metadata?.roles?.includes("admin") || false;
  if (!isOwner && !isAdmin) {
    set.status = 403;
    return { success: false, error: "Accès refusé" };
  }

  // === Nettoyage et validation du body (corrige l'erreur TS) ===
  const updates: Record<string, any> = {};
  if (typeof body === "object" && body !== null) {
    const b = body as any;
    if (b.name !== undefined) updates.name = String(b.name).trim();
    if (b.price !== undefined) {
      const p = parseFloat(b.price);
      if (!isNaN(p)) updates.price = p;
    }
    if (b.quantity !== undefined) {
      const q = parseInt(b.quantity);
      if (!isNaN(q)) updates.quantity = q;
    }
    if (b.image_url !== undefined) updates.image_url = b.image_url || null;
    if (b.date !== undefined) updates.date = b.date;
  }

  if (Object.keys(updates).length === 0) {
    set.status = 400;
    return { success: false, error: "Aucune donnée à mettre à jour" };
  }

  // === Mise à jour ===
  const { data, error } = await supabase
    .from("products")
    .update(updates)
    .eq("id", id)
    .select()
    .single();

  if (error) {
    set.status = 400;
    return { success: false, error: error.message };
  }

  return { success: true, product: data };
});

// === 4. Supprimer un produit (seul le propriétaire) ===
app.delete("/product/delete/:id", async ({ params, headers, set }) => {
  const { id } = params;
  const token = headers.authorization?.replace("Bearer ", "");

  const {
    data: { user },
    error: authError,
  } = await supabase.auth.getUser(token);
  if (authError || !user) {
    set.status = 401;
    return { success: false, error: "Unauthorized" };
  }

  // Vérifie que c'est bien son produit (ou admin)
  const { data: product, error: fetchError } = await supabase
    .from("products")
    .select("vendor_id")
    .eq("id", id)
    .single();

  if (fetchError || !product) {
    set.status = 404;
    return { success: false, error: "Produit non trouvé" };
  }

  if (
    product.vendor_id !== user.id &&
    !user.user_metadata?.roles?.includes("admin")
  ) {
    set.status = 403;
    return { success: false, error: "Accès refusé" };
  }

  // ÉTAPE CLÉ : On vérifie s'il y a des messages liés
  const { count, error: countError } = await supabase
    .from("messages")
    .select("*", { count: "exact", head: true })
    .eq("product_id", id);

  if (countError) {
    set.status = 500;
    return { success: false, error: "Erreur serveur" };
  }

  // S'IL Y A DES MESSAGES → SOFT DELETE (on masque)
  if (count && count > 0) {
    const { error } = await supabase
      .from("products")
      .update({
        active: false,
        is_deleted: true,
        deleted_at: new Date().toISOString(),
      })
      .eq("id", id);

    if (error) {
      set.status = 400;
      return { success: false, error: error.message };
    }

    return {
      success: true,
      message: "Produit archivé (il a des messages)",
      soft_deleted: true,
    };
  }

  // S'IL N'Y A PAS DE MESSAGES → SUPPRESSION TOTALE
  const { error: deleteError } = await supabase
    .from("products")
    .delete()
    .eq("id", id);

  if (deleteError) {
    set.status = 400;
    return { success: false, error: deleteError.message };
  }

  return {
    success: true,
    message: "Produit supprimé définitivement",
    soft_deleted: false,
  };
});

// === 5. Lister tous les produits (public ou admin) ===
app.get("/product/list", async ({ headers, set }) => {
  const { data, error } = await supabase
    .from("products")
    .select("*, vendor:vendors(shop_name, photo_url, location, phone)")
    .order("created_at", { ascending: false });

  if (error) {
    set.status = 400;
    return { success: false, error: error.message };
  }

  return { success: true, products: data || [] };
});

app.listen(4000);
console.log("🚀 API running on http://localhost:4000");
