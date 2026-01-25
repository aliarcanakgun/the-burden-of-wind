shader_type canvas_item;

// --- Doku ve Boyut Ayarları ---
uniform sampler2D main_noise_texture : source_color, repeat_enable, filter_linear_mipmap;
uniform vec2 box_size = vec2(0.8, 0.8);

// --- Köşe Yarıçapları (Ayrı Ayrı) ---
uniform float radius_top_left : hint_range(0.0, 0.5) = 0.1;
uniform float radius_top_right : hint_range(0.0, 0.5) = 0.1;
uniform float radius_bottom_right : hint_range(0.0, 0.5) = 0.1;
uniform float radius_bottom_left : hint_range(0.0, 0.5) = 0.1;

// --- Gürültü Ayarları ---
uniform float roughness_intensity : hint_range(0.0, 0.3) = 0.08;

// ARTIK 0.0 OLABİLİR
// 0.0 olduğunda "Hard Edge" moduna geçer.
uniform float edge_softness : hint_range(0.0, 0.05) = 0.0;

// --- Yardımcı Fonksiyonlar ---

vec2 sdRoundedBoxWithMask(vec2 p, vec2 b, vec4 r) {
    // 1. Doğru yarıçapı seç (Quadrant kontrolü)
    r.xy = (p.x > 0.0) ? r.xy : r.zw;
    r.x  = (p.y > 0.0) ? r.x  : r.y;

    // 2. Mesafeyi hesapla
    vec2 q = abs(p) - b + r.x;

    // 3. Köşe Maskesi (Sadece kıvrımlı alanlar ve radius > 0 ise)
    float is_in_corner_zone = (q.x > 0.0 && q.y > 0.0 && r.x > 0.001) ? 1.0 : 0.0;

    float dist = min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r.x;

    return vec2(dist, is_in_corner_zone);
}

void fragment() {
    vec2 centered_uv = UV - 0.5;

    // Radius vektörü: (Bottom-Right, Top-Right, Bottom-Left, Top-Left)
    vec4 radii = vec4(radius_bottom_right, radius_top_right, radius_bottom_left, radius_top_left);

    // SDF hesapla
    vec2 sdf_result = sdRoundedBoxWithMask(centered_uv, box_size * 0.5, radii);
    float dist = sdf_result.x;
    float corner_mask = sdf_result.y;

    // Noise uygula
    float noise_val = texture(main_noise_texture, UV).r;
    // [-1, 1] aralığına genişlet (daha belirgin etki için)
    float noise_perturbation = (noise_val - 0.5) * 2.0;

    // Noise'u sadece köşelere uygula
    dist += noise_perturbation * roughness_intensity * corner_mask;

    // --- MASKELEME MANTIĞI GÜNCELLENDİ ---
    float alpha_mask;

    if (edge_softness <= 0.0001) {
        // HARD CUT (Keskin Kenar)
        // step(edge, x): x < edge ise 0.0, değilse 1.0 döner.
        // dist < 0.0 ise şeklin içindeyiz.
        // step(0.0, dist) -> İçerideyken 0 döner, dışarıdayken 1.
        // Biz içerisini beyaz (1.0) istiyoruz, o yüzden tersini alıyoruz.
        alpha_mask = 1.0 - step(0.0, dist);
    } else {
        // SOFT CUT (Yumuşak Kenar / Anti-Aliasing)
        // smoothstep kullanarak geçişli kenar oluşturur.
        alpha_mask = 1.0 - smoothstep(-edge_softness, edge_softness, dist);
    }

    vec4 tex_color = texture(main_noise_texture, UV);

    // Sonucu ata
    COLOR = vec4(tex_color.rgb, tex_color.a * alpha_mask);
}