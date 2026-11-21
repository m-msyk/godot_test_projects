// "Occlusion see-through": when the player is completely hidden behind something,
// OcclusionRevealComponent (components/occlusion_reveal_component.gd) opens a circular
// hole through whatever stands between the camera and the player, so the player stays
// visible. The hole is a CONE with its tip at the camera, aimed at the player, so it is the
// same size on screen whatever depth it cuts through: a true circle centred on the player.
// (A cylinder of fixed width looks bigger on near leaves and smaller on far ones.)
//
// Global shader parameters (Project Settings > Shader Globals). Radius 0 = no hole.
global uniform float cel_reveal_radius;
global uniform vec3 cel_reveal_center; // world position of the player's centre

// things this close in front of the player's centre are never cut (the player's own body)
const float REVEAL_KEEP_NEAR = 0.8;
// the player's centre is this far above their feet
const float REVEAL_CENTRE_HEIGHT = 0.9;
// surfaces within this height of the feet are never cut: the ground in front of the player
const float REVEAL_KEEP_GROUND = 0.35;

bool cel_reveal_cut(vec3 world_pos, vec3 cam_pos) {
	if (cel_reveal_radius <= 0.0) {
		return false;
	}
	if (world_pos.y < cel_reveal_center.y - REVEAL_CENTRE_HEIGHT + REVEAL_KEEP_GROUND) {
		return false;
	}
	vec3 to_player = cel_reveal_center - cam_pos;
	float dist = length(to_player);
	vec3 dir = to_player / dist;
	vec3 to_frag = world_pos - cam_pos;
	float along = dot(to_frag, dir);
	if (along > dist - REVEAL_KEEP_NEAR) {
		return false; // at or behind the player
	}
	// cone: the allowed distance from the camera->player line grows with depth, reaching
	// the full radius at the player's own depth
	return length(to_frag - dir * along) < cel_reveal_radius * (along / dist);
}
