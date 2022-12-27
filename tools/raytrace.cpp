#include <cstdlib>
#include <cstring>

#include <thread>
#include <functional>
#include <vector>

#include <glm/glm.hpp>

#include "stb_image_write.h"

struct Image {
    glm::ivec2 size;
    uint8_t *data;
};

struct Camera {
    glm::vec3 eye;
    glm::vec3 target;

    glm::mat3 view;

    float fov;
    float aspect;
};

struct Ray {
    glm::vec3 origin;
    glm::vec3 direction;
};

Ray BuildRay(const Camera &cam, const glm::vec2 &p) {
    Ray r;

    float ay = tan(M_PI * cam.fov / 2.f);
    float ax = ay * cam.aspect;
    
    r.origin = cam.eye;
    r.direction = glm::normalize(cam.view * glm::vec3(ax*p.x, ay*p.y, 2.f));

    return r;
}

float Box(const glm::vec3& p, const glm::vec3& b) {
    glm::vec3 d = glm::abs(p) - b;
    return glm::length(glm::max(d, 0.f)) + glm::min(glm::max(d.x,glm::max(d.y, d.z)), 0.f);
}

float Map(glm::vec3 p) {
    p.z = glm::mod(p.z, 8.f);

    float d = Box( p - glm::vec3( 0.0, 1.0, 1.0 ), glm::vec3( 1.5, 0.5, 0.5 ) );
    d = glm::min( d, Box( p - glm::vec3( 1.0, 0.0, 1.0 ), glm::vec3( 0.5 ) ) );
    d = glm::min( d, Box( p - glm::vec3( -1.0, 1.0, 3.0 ), glm::vec3( 0.5, 0.5, 1.5 ) ) );
    d = glm::min( d, Box( p - glm::vec3( -1.0, 0.0, 5.0 ), glm::vec3( 0.5, 1.5, 0.5 ) ) );
    d = glm::min( d, Box( p - glm::vec3( 0.0, -1.0, 5.0 ), glm::vec3( 0.5 ) ) );
    d = glm::min( d, Box( p - glm::vec3( 1.0, -1.0, 6.5 ), glm::vec3( 0.5, 0.5, 2.0 ) ) );
    d = glm::min( d, Box( p - glm::vec3( 1.0, -1.0, 0.5 ), glm::vec3( 0.5, 0.5, 1.0 ) ) );

    return d;
}

glm::vec3 Normal(const glm::vec3 &p) {
    static const float delta = 0.005f;
    
    float dp = Map(p);

    return glm::normalize(glm::vec3(dp - Map(p - glm::vec3(delta, 0.f, 0.f)), dp - Map(p - glm::vec3(0.f, delta, 0.f)), dp - Map(p - glm::vec3(0.f, 0.f, delta))));
}

float Trace(const Ray& r) {
    const float t_min = 0.01f;
    const float t_max = 20.f;
    const float dt_eps = 0.001f;

    float t = t_min;
    int i;
    for(i=0; i<64; i++) {
        glm::vec3 p = r.origin + t * r.direction;
        float dt = Map(p);

        if(dt < dt_eps) {
            break;
        }
        if(t >= t_max) {
            return -1.f;
        }

        t += dt;
    }
    return t;
}

void Render(const glm::ivec4& viewport, const Camera& cam, Image &out) {
    glm::vec3 p;

    for(int y=viewport.y; (y<(viewport.y + viewport.w)) && (y < out.size.y); y++) {
        p.y = 2.f * ((y + 0.5f) / (float)out.size.y) - 1.f;

        for(int x=viewport.x; (x<(viewport.x + viewport.z)) && (x < out.size.x); x++) {
            p.x = 1.f - 2.f * ((x + 0.5f) / (float)out.size.x);

            Ray r = BuildRay(cam, p);

            float t = Trace(r);
        
            glm::vec3 position = r.origin + t * r.direction;
            glm::vec3 normal = Normal(position);

            float fog_start = 0.1f;
            float f = abs(position.z - cam.eye.z) - fog_start;
            f = 0.07 * ((f < 0.f) ? 0.f : f);
            float fog = 1.f/exp(f);
            //float fog = 1.f/exp(f*f);

            glm::vec3 col = fog * ((t > 0.f)  ? glm::abs(normal) : glm::vec3(0.f));// * 0.5f + 0.5f;

            int offset = 3 * (x + y*out.size.x);
            out.data[offset + 0] = col.x * 255.f;
            out.data[offset + 1] = col.y * 255.f;
            out.data[offset + 2] = col.z * 255.f;
        }
    }

}

int main(int argc, char **argv) {
    Image img;
    Camera cam;

    img.size.x = 40*8;
    img.size.y = 25*8;
    img.data = new uint8_t[3 * img.size.x * img.size.y];

    cam.aspect = img.size.x / (float)img.size.y;
    cam.fov = M_PI * 30.f / 180.f;
    cam.eye = glm::vec3(0.f);
    cam.target = glm::vec3(0.f, 0.f, 1.f);
    
    unsigned int cpus = std::thread::hardware_concurrency();
    int n = floor(sqrt(cpus));
    int width = img.size.x;
    int height = img.size.y;
    if(n > 1) {
        width /= n;
        height /= n;
    } else {
        width /= cpus;
    }

    std::vector<std::thread> th;
    char filename[256];

    int frame_count = 24;
    float r_target = 0.5f;
    float r_eye = 0.6;

    for(int frame=0; frame<frame_count; frame++) {
        printf("=> frame %d\n", frame);

        float t = frame / (float)frame_count;
        float cs = cos(2.f * M_PI * t + M_PI);
        float sn = sin(2.f * M_PI * t + M_PI);

        cam.eye = glm::vec3(r_eye*sn, r_eye*cs*sn, -24.f * t);

        cs = cos(2.f * M_PI * t);
        sn = sin(2.f * M_PI * t);
        cam.target = cam.eye + glm::vec3(r_target*sn, r_target*cs*sn, -2.f);

        glm::vec3 w = glm::normalize(cam.target - cam.eye);
        glm::vec3 u = glm::cross(w, glm::vec3(0.f, 1.f, 0.f));
        glm::vec3 v = glm::cross(u, w);

        glm::vec3 rx = glm::vec3(cs,-sn, 0.f);
        glm::vec3 ry = glm::vec3(sn, cs, 0.f);
        glm::vec3 rz = glm::vec3(0.f, 0.f, 1.f);

        cam.view = glm::mat3(u, v, w);
//            cam.view = glm::mat3(u, v, w) * glm::mat3(rx, ry, rz);
        for(int y=0; y<img.size.y; y+=height) {
            int w = width;
            if((y + 2*height) > img.size.y) {
                height = img.size.y - y;
            }

            for(int x = 0; x<img.size.x; x+=w) {
                if((x + 2*x) > img.size.x) {
                    x = img.size.x - x;
                }
                th.push_back(std::thread(std::bind(Render, glm::ivec4(x,y,w,height), cam, img)));
            }
        }

        for(auto &t : th) {
            if(t.joinable()) {
                t.join();
            }
        }

        snprintf(filename, 256, "out_%d.png", frame+1);
        stbi_write_png(filename, img.size.x, img.size.y, 3, img.data, 0);
    }

    delete [] img.data;

    return EXIT_SUCCESS;
}