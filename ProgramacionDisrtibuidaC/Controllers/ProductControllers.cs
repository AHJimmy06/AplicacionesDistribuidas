using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ProgramacionDisrtibuidaC.Data;
using ProgramacionDisrtibuidaC.DTO;
using ProgramacionDisrtibuidaC.Models;
using ProgramacionDisrtibuidaC.Services;

namespace ProgramacionDisrtibuidaC.Controllers
{
    [Route("api/Products")]
    [ApiController]
    public class ProductControllers : ControllerBase
    {
        private readonly ProductService _service;
        private readonly AppDbContext _context;

        public ProductControllers(
            ProductService service,
            AppDbContext context)
        {
            _service = service;
            _context = context;
        }


        private static DTOProductos ToDto(Product product)
        {
            return new DTOProductos
            {
                Id = product.Id,
                Name = product.Name,
                Price = product.Price,
                Stock = product.Stock,
                Description = product.Description,
                ImageUrl = product.ImageUrl,
                IsActive = product.IsActive,

                Versions = Convert.ToBase64String(
                    product.Versions
                )
            };
        }

        [HttpGet]
        public async Task<ActionResult<List<DTOProductos>>> GetAll()
        {
            var products = await _service.GetAllAsync();

            var result = products
                .Select(product => ToDto(product))
                .ToList();

            return Ok(result);
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<DTOProductos>> GetById(int id)
        {
            var product = await _service.GetByIdAsync(id);

            if (product == null)
            {
                return NotFound(new
                {
                    mensaje = "Producto no encontrado."
                });
            }

            var dto = ToDto(product);

            return Ok(dto);
        }


        [HttpPost]
        public async Task<ActionResult<DTOProductos>> CreateProduct(
            Product product)
        {
            product.Name = product.Name.Trim();
            product.Description = product.Description.Trim();
            product.ImageUrl = product.ImageUrl.Trim();

            _context.Product.Add(product);

            await _context.SaveChangesAsync();

            var dto = ToDto(product);

            return CreatedAtAction(
                nameof(GetById),
                new { id = product.Id },
                dto
            );
        }


        [HttpPut("{id}")]
        public async Task<IActionResult> Update(
            int id,
            DTOProductos dto)
        {
            try
            {
                if (id != dto.Id)
                {
                    return BadRequest(new
                    {
                        error = "El ID de la ruta no coincide con el ID del producto."
                    });
                }

                if (string.IsNullOrWhiteSpace(dto.Versions))
                {
                    return BadRequest(new
                    {
                        error = "La versión del producto es obligatoria."
                    });
                }

                byte[] versionBytes =
                    Convert.FromBase64String(dto.Versions);


                var product = new Product
                {
                    Id = dto.Id,
                    Name = dto.Name,
                    Price = dto.Price,
                    Stock = dto.Stock,
                    Description = dto.Description,
                    ImageUrl = dto.ImageUrl,
                    IsActive = dto.IsActive,

                    Versions = versionBytes
                };


                await _service.UpdateAsync(
                    id,
                    product,
                    versionBytes
                );


                return Ok(new
                {
                    mensaje = "Producto actualizado correctamente."
                });
            }

            catch (FormatException)
            {
                return BadRequest(new
                {
                    error = "La versión enviada no tiene un formato Base64 válido."
                });
            }


            catch (InvalidOperationException ex)
            {
                return Conflict(new
                {
                    error = "Conflicto de concurrencia",
                    mensaje = ex.Message
                });
            }

            catch (ArgumentException ex)
            {
                return BadRequest(new
                {
                    error = ex.Message
                });
            }

            catch (ValidationException ex)
            {
                return BadRequest(new
                {
                    error = ex.Message
                });
            }
        }


        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteProduct(
            int id,
            [FromQuery] string? versions)
        {
            if (string.IsNullOrWhiteSpace(versions))
            {
                return BadRequest(new
                {
                    mensaje = "La versión del producto es obligatoria."
                });
            }


            byte[] versionBytes;

            try
            {
                versionBytes =
                    Convert.FromBase64String(versions);
            }
            catch (FormatException)
            {
                return BadRequest(new
                {
                    mensaje = "La versión enviada no tiene un formato Base64 válido."
                });
            }


            var product =
                await _context.Product.FindAsync(id);


            if (product == null)
            {
                return NotFound(new
                {
                    mensaje = "El producto no existe o ya fue eliminado."
                });
            }


            // Indicamos a Entity Framework cuál era
            // la versión conocida por el cliente.

            _context.Entry(product)
                .Property(p => p.Versions)
                .OriginalValue = versionBytes;


            _context.Product.Remove(product);


            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                return Conflict(new
                {
                    error = "Conflicto de concurrencia",

                    mensaje =
                        "Otro usuario modificó el producto antes de que pudiera eliminarse. Recargue los datos e inténtelo nuevamente."
                });
            }


            return NoContent();
        }
    }
}